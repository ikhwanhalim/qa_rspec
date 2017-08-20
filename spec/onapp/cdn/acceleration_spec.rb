require 'spec_helper'
require './groups/cdn_server_actions'
require './spec/onapp/cdn/shared_examples/cdn_server'
require './groups/virtual_server_actions'

describe 'Acceleration ->' do
  before :all do
    INSTALL_HTTP = 'yum install httpd -y;chkconfig --levels 3 httpd on;service httpd start;echo "it Works" > /var/www/html/index.html;'
    #Accelerator
    @vma = CdnServerActions.new.precondition
    @acc = @vma.virtual_machine
    @template = @vma.template
    @cp_version = @vma.version
    #VS
    @vsa = VirtualServerActions.new.precondition
    @vs = @vsa.virtual_machine
    @template = @vsa.template
    @hypervisor = @vsa.hypervisor
    if @vs.ip_range_id == @acc.ip_range_id
      Log.info('Congrats, Your VM and Accelerator are in the same IpRange'.white)
    else
      @vs.destroy
      @vs.create(hypervisor_id: @acc.hypervisor.id, data_store_id: @acc.disk.data_store_id, \
                 label: Faker::Internet.domain_word, required_ip_address_assignment: 1, primary_disk_size: 7, \
                 swap_disk_size: 1, network_id: @acc.network_id, ip_net_id: @acc.ip_net_id, ip_range_id: @acc.ip_range_id)
    end
  end

  after :all do
    unless CdnServerActions::IDENTIFIER
      @acc.destroy
    end

    unless VirtualServerActions::IDENTIFIER
      @vs.destroy if @vs
      @template.remove if @vs.find_by_template(@template.id).empty?
    end
  end

  let(:acc) { @vma.virtual_machine }
  let(:vs)  { @vsa.virtual_machine }

  context 'preconfigure/precheck ->' do
    it 'onapp-messaging on HV' do
      if @vma.settings.rabbitmq_host == '127.0.0.1' || @vma.settings.rabbitmq_host == 'localhost'
        Log.error("Please, set the correct ip address for rabbitmq_host in on_app.yml file.Currently it is: #{@vma.settings.rabbitmq_host}.".white)
      else
        acc.configure_onapp_messaging
        sleep 20
      end

      expect(acc.onapp_messaging('status').include?('active')).to be true
      Log.error("Looks like the 'onapp-messaging' service is not running on the HV, please take a look.".white) unless acc.onapp_messaging('status').include?('active')
    end

    it 'Accelerator' do
      expect(acc.pinged?).to be true
      Log.error("Something wrong with Accelerator, current cdn_server status is: #{acc.edge_status}".white) unless acc.edge_status == 'Active'
    end

    it 'VS' do
      expect(vs.pinged?).to be true
      vs.interface.execute_with_keys(vs.ip_address, 'root', 'chkconfig --levels 3 httpd on;service httpd start')

      if vs.content_is_not_accelerated?(max = 20, frequency = 2)
        Log.info("HTTP is already installed on your VS and available by curl. So we skip installing HTTP by rspec.".white)
      else
        Log.info("Look like HTTP is not installed or not available by curl. So rspec will try to install HTTP.".white)
        vs.interface.execute_with_keys(vs.ip_address, 'root', INSTALL_HTTP)
      end

      expect(vs.content_is_not_accelerated?(max = 20, frequency = 2)).to be true
      Log.error("Looks like the httpd is not working on your VS, please take a look".white) unless vs.content_is_not_accelerated?
    end
  end

  context 'simple enabling/disabling acceleration' do
    after :all do
      @vs.decelerate
    end

    it 'enable acceleration' do
      vs.accelerate
      expect(vs.content_is_accelerated?).to be true
      expect(vs.acceleration).to be true
      vs.info_update
      expect(vs.acceleration_status).to eq 'Active'
    end

    it 'disable acceleration' do
      vs.decelerate
      expect(vs.content_is_not_accelerated?).to be true
      expect(vs.acceleration).to be false
      expect(vs.acceleration_status).to eq 'Inactive'
    end
  end

  context 'Accelerator ->' do
    context 'power operations ->' do
      before :all do
        @vs.accelerate
        @vs_mac = @vs.network_interface.mac_address
        @acc_mac = @acc.network_interface.mac_address
      end

      after :all do
        @vs.decelerate
      end

      it 'shutdown' do
        acc.stop
        expect(vs.check_ebtables_rules(@vs_mac)).to eq 0
        expect(acc.check_ebtables_rules(@acc_mac)).to eq 0
        expect(acc.booted).to be false
        expect(acc.not_pinged?).to be true
        expect(vs.content_is_not_accelerated?).to be true
        vs.info_update
        expect(vs.acceleration).to be true
        expect(vs.acceleration_status).to eq 'Inactive'
      end

      it 'startup' do
        acc.start_up
        expect(vs.check_ebtables_rules(@vs_mac)).to eq 3
        expect(acc.check_ebtables_rules(@acc_mac)).to eq 1
        expect(acc.booted).to be true
        expect(acc.pinged?).to be true
        expect(vs.content_is_accelerated?).to be true
        vs.info_update
        expect(vs.acceleration).to be true
        expect(vs.acceleration_status).to eq 'Active'
      end

      it 'reboot' do
        acc.reboot
        expect(acc.booted).to be true
        expect(acc.pinged?).to be true
        expect(vs.content_is_accelerated?).to be true
        vs.info_update
        expect(vs.acceleration).to be true
        expect(vs.acceleration_status).to eq 'Active'
      end

      it 'Suspend' do
        acc.suspend
        expect(vs.check_ebtables_rules(@vs_mac)).to eq 0
        expect(acc.check_ebtables_rules(@acc_mac)).to eq 0
        expect(acc.not_pinged?).to be true
        expect(acc.booted).to be false
        expect(acc.edge_status).to eq 'Paused'
        expect(vs.content_is_not_accelerated?).to be true
        vs.info_update
        expect(vs.acceleration).to be true
        expect(vs.acceleration_status).to eq 'Inactive'
      end

      it 'Unsuspend and Startup' do
        acc.unsuspend
        expect(vs.check_ebtables_rules(@vs_mac)).to eq 0
        expect(acc.check_ebtables_rules(@acc_mac)).to eq 0
        expect(acc.down?).to be true
        expect(vs.content_is_not_accelerated?).to be true
        vs.info_update
        expect(vs.acceleration).to be true
        expect(vs.acceleration_status).to eq 'Inactive'
        acc.start_up
        expect(acc.pinged?).to be true
        expect(vs.content_is_accelerated?).to be true
        vs.info_update
        expect(vs.acceleration).to be true
        expect(vs.acceleration_status).to eq 'Active'
        expect(vs.check_ebtables_rules(@vs_mac)).to eq 3
        expect(acc.check_ebtables_rules(@acc_mac)).to eq 1
      end
    end

    context 'edit ->' do
      before :all do
        @vs.accelerate
      end

      after :all do
        @vs.decelerate
      end

      it 'RAM' do
        new_ram = acc.memory.to_i + 10
        acc.edit(memory: new_ram)
        expect(acc.memory).to eq new_ram
        expect(vs.content_is_accelerated?).to be true
      end

      it 'CPU' do
        new_cpus = acc.cpus + 1
        acc.edit_cpus(cpus: new_cpus)
        expect(acc.cpus).to eq new_cpus
        expect(vs.content_is_accelerated?).to be true
      end

      it 'Label' do
        new_label = "#{acc.label}-edit"
        acc.edit(label: new_label)
        expect(acc.label).to eq new_label
        expect(vs.content_is_accelerated?).to be true
      end

      it 'set vip' do
        skip "https://onappdev.atlassian.net/browse/CORE-8814"
        if acc.vip == (nil || false)
          acc.set_vip({vip: "true"})
          expect(acc.vip).to eq true
        else
          vm.set_vip({vip: "false"})
          expect(acc.vip).to eq false
        end

        expect(vs.content_is_accelerated?).to be true
      end
    end

    context 'network ->' do
      before :all do
        @vs.accelerate
      end

      after :all do
        @vs.decelerate
      end

      it 'Update port speed' do
        current_port_speed = acc.network_interface.port_speed
        port_speed = case
                       when current_port_speed == 0
                         Faker::Number.between(1, 1000)
                       when current_port_speed >= 501
                         current_port_speed - Faker::Number.between(1, 400)
                       else
                         current_port_speed + Faker::Number.between(1, 400)
                     end

        acc.network_interface.edit(rate_limit: port_speed)
        expect(acc.network_interface.rate_limit).to eq port_speed
        expect(acc.network_interface.port_speed).to eq port_speed
        expect(vs.content_is_accelerated?).to be true
      end

      it 'rebuild' do
        acc.rebuild_network
        expect(vs.content_is_accelerated?(max = 900, frequency = 60)).to be true
      end

      it 'change ip' do
        second_ip = acc.network_interface.ip_address.free_ip
        skip("No enough free ip address") unless second_ip
        acc.network_interface.allocate_new_ip(address: second_ip)
        expect(acc.ip_addresses.count).to eq 2
        acc.network_interface.remove_ip(1)
        acc.rebuild_network
        expect(acc.ip_addresses.count).to eq 1
        expect(vs.content_is_accelerated?(max = 900, frequency = 60)).to be true
      end
    end

    context 'migrate ->' do
    end
  end

  context 'VS ->' do
    context 'power operations ->' do
      before :all do
        @vs.accelerate
        @vs.info_update
        @vs.start_up unless @vs.booted
        @vs_mac = @vs.network_interface.mac_address
        @acc_mac = @acc.network_interface.mac_address
      end

      after :all do
        @vs.decelerate
      end

      it 'shutdown' do
        vs.stop
        expect(vs.check_ebtables_rules(@vs_mac)).to eq 3
        expect(acc.check_ebtables_rules(@acc_mac)).to eq 1
        expect(vs.booted).to be false
        expect(vs.not_pinged?).to be true
      end

      it 'startup' do
        vs.start_up
        expect(vs.check_ebtables_rules(@vs_mac)).to eq 3
        expect(acc.check_ebtables_rules(@acc_mac)).to eq 1
        expect(vs.booted).to be true
        expect(vs.pinged?).to be true
        expect(vs.content_is_accelerated?).to be true
        vs.info_update
        expect(vs.acceleration).to be true
        expect(vs.acceleration_status).to eq 'Active'
      end

      it 'reboot' do
        vs.reboot
        expect(vs.booted).to be true
        expect(vs.pinged?).to be true
        expect(vs.content_is_accelerated?).to be true
        vs.info_update
        expect(vs.acceleration).to be true
        expect(vs.acceleration_status).to eq 'Active'
      end

      it 'Suspend/Unsuspend/Startup' do
        vs.suspend
        expect(vs.not_pinged?).to be true
        expect(vs.booted).to be false
        expect(vs.check_ebtables_rules(@vs_mac)).to eq 3
        expect(acc.check_ebtables_rules(@acc_mac)).to eq 1
        vs.unsuspend
        expect(vs.down?).to be true
        expect(vs.not_pinged?).to be true
        expect(vs.check_ebtables_rules(@vs_mac)).to eq 3
        expect(acc.check_ebtables_rules(@acc_mac)).to eq 1
        vs.start_up
        expect(vs.pinged?).to be true
        expect(vs.check_ebtables_rules(@vs_mac)).to eq 3
        expect(acc.check_ebtables_rules(@acc_mac)).to eq 1
        expect(vs.content_is_accelerated?).to be true
        vs.info_update
        expect(vs.acceleration).to be true
        expect(vs.acceleration_status).to eq 'Active'
      end

      it 'decelerate, shutdown, accelerate and start_up' do
        vs.decelerate
        expect(vs.check_ebtables_rules(@vs_mac)).to eq 0
        # todo calc if acceleration is used by another VS, sometime the next 'expect' can be eq 1
        expect(acc.check_ebtables_rules(@acc_mac)).to eq 0
        expect(vs.content_is_not_accelerated?).to be true
        vs.stop
        expect(vs.acceleration).to be false
        expect(vs.acceleration_status).to eq 'Inactive'
        expect(vs.check_ebtables_rules(@vs_mac)).to eq 0
        expect(acc.check_ebtables_rules(@acc_mac)).to eq 0
        expect(vs.booted).to be false
        expect(vs.not_pinged?).to be true
        vs.accelerate
        expect(vs.check_ebtables_rules(@vs_mac)).to eq 3
        expect(acc.check_ebtables_rules(@acc_mac)).to eq 1
        vs.info_update
        expect(vs.acceleration).to be true
        expect(vs.acceleration_status).to eq 'Active'
        vs.start_up
        expect(vs.check_ebtables_rules(@vs_mac)).to eq 3
        expect(acc.check_ebtables_rules(@acc_mac)).to eq 1
        expect(vs.booted).to be true
        expect(vs.pinged?).to be true
        expect(vs.content_is_accelerated?).to be true
        vs.info_update
        expect(vs.acceleration).to be true
        expect(vs.acceleration_status).to eq 'Active'
      end

      it 'shutdown/decelerate/startup' do
        vs.info_update
        vs.start_up unless vs.booted
        vs.stop
        expect(vs.check_ebtables_rules(@vs_mac)).to eq 3
        expect(acc.check_ebtables_rules(@acc_mac)).to eq 1
        expect(vs.booted).to be false
        expect(vs.not_pinged?).to be true
        vs.decelerate
        expect(vs.check_ebtables_rules(@vs_mac)).to eq 0
        # todo calc if acceleration is used by another VS, sometime the next 'expect' can be eq 1(the sane as in the previous test)
        expect(acc.check_ebtables_rules(@acc_mac)).to eq 0
        expect(vs.acceleration).to be false
        expect(vs.acceleration_status).to eq 'Inactive'
        vs.start_up
        expect(vs.check_ebtables_rules(@vs_mac)).to eq 0
        expect(acc.check_ebtables_rules(@acc_mac)).to eq 0
        expect(vs.booted).to be true
        expect(vs.pinged?).to be true
        expect(vs.content_is_not_accelerated?).to be true
        vs.info_update
        expect(vs.acceleration).to be false
        expect(vs.acceleration_status).to eq 'Inactive'
      end
    end

    context 'edit ->' do
      before :all do
        @vs.accelerate
        @vs.info_update
        @vs.start_up unless @vs.booted
      end

      after :all do
        @vs.decelerate
      end

      it 'RAM' do
        new_ram = vs.memory.to_i + 10
        vs.edit(memory: new_ram)
        expect(vs.memory).to eq new_ram
        expect(vs.content_is_accelerated?).to be true
      end

      it 'Label' do
        new_label = "#{vs.label}-edit"
        vs.edit(label: new_label)
        expect(vs.label).to eq new_label
        expect(vs.content_is_accelerated?).to be true
      end

      it 'set vip' do
        skip "https://onappdev.atlassian.net/browse/CORE-8814"
        if vs.vip == (nil || false)
          vs.set_vip({vip: "true"})
          expect(vs.vip).to eq true
        else
          vs.set_vip({vip: "false"})
          expect(vs.vip).to eq false
        end

        expect(vs.content_is_accelerated?).to be true
      end
    end

    context 'network ->' do
      before :all do
        @vs.accelerate
        @vs.info_update
        @vs.start_up unless @vs.booted
      end

      after :all do
        @vs.decelerate
      end

      it 'Update port speed' do
        current_port_speed = vs.network_interface.port_speed
        port_speed = case
                       when current_port_speed == 0
                         Faker::Number.between(1, 1000)
                       when current_port_speed >= 501
                         current_port_speed - Faker::Number.between(1, 400)
                       else
                         current_port_speed + Faker::Number.between(1, 400)
                     end

        vs.network_interface.edit(rate_limit: port_speed)
        expect(vs.network_interface.rate_limit).to eq port_speed
        expect(vs.network_interface.port_speed).to eq port_speed
        expect(vs.content_is_accelerated?).to be true
      end

      it 'rebuild' do
        vs.rebuild_network
        expect(vs.content_is_accelerated?(max = 1000, frequency = 30)).to be true
      end

      it 'change ip' do
        second_ip = vs.network_interface.ip_address.free_ip
        skip("No enough free ip address") unless second_ip
        vs.network_interface.allocate_new_ip(address: second_ip)
        expect(vs.ip_addresses.count).to eq 2
        vs.network_interface.remove_ip(1)
        vs.rebuild_network
        expect(vs.ip_addresses.count).to eq 1
        expect(vs.content_is_accelerated?(max = 1000, frequency = 30)).to be true
      end
    end

    context 'purge ->' do
      it 'all(acceleration is enabled)' do
        vs.accelerate
        expect(vs.acceleration).to be true
        vs.purge(all: true)
        expect(vs.api_response_code).to eq '200'  #TODO change assert when CORE-9989 is done
        expect(@vsa.conn.page.body.notice).to eq 'The request has been executed and contents will be purged within 5 minutes'
      end

      it 'all(acceleration is disabled)' do
        vs.decelerate
        expect(vs.acceleration).to be false
        vs.purge(all: true)
        expect(vs.api_response_code).to eq '403'
      end

      it 'file(acceleration is enabled)' do
        vs.accelerate
        expect(vs.acceleration).to be true
        vs.purge(path_to_file: Faker::Internet.url)
        expect(vs.api_response_code).to eq '200'
        expect(@vsa.conn.page.body.notice).to eq 'The Purge request was successfully scheduled'
      end

      it 'files(acceleration is enabled)' do
        vs.accelerate
        expect(vs.acceleration).to be true
        vs.purge(path_to_file: [ Faker::Internet.url, Faker::Internet.url ])
        expect(vs.api_response_code).to eq '200'
        expect(@vsa.conn.page.body.notice).to eq 'The Purge request was successfully scheduled'
      end

      it 'file(acceleration is enabled and path_to_file is wrong)' do
        wrong_path = Faker::Internet.domain_name
        vs.accelerate
        expect(vs.acceleration).to be true
        vs.purge(path_to_file: wrong_path)
        expect(vs.api_response_code).to eq '422'
        expect(@vsa.conn.page.body.errors).to eq ["An error occurred during Purge. Invalid URL '#{wrong_path}'"]
      end

      it 'file(acceleration is disabled)' do
        vs.decelerate
        expect(vs.acceleration).to be false
        vs.purge(path_to_file: Faker::Internet.url)
        expect(vs.api_response_code).to eq '403'
      end
    end
  end
end

describe 'rake task, configure messaging' do
  # TODO rake task, configure messaging
end