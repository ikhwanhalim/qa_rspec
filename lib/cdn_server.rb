require 'virtual_server'

class CdnServer < VirtualServer

  CDN_SERVER          = ENV['CDN_SERVER']       # edge_server or storage_server
  CDN_SERVER_TYPE     = ENV['CDN_SERVER_TYPE']  # streaming or http

  attr_reader :edge_status

  def create(**params)
    data = interface.post("/#{CDN_SERVER}s", {ENV['CDN_SERVER'] => build_params.merge(params)})
    return data.errors if data.errors
    info_update(data)
    wait_for_build
    info_update
    self
  end

  def build_params
    type = unless CDN_SERVER == 'accelerator'
             {"#{ENV['CDN_SERVER']}_type" => ENV['CDN_SERVER_TYPE']}
           else
             {
               cpus: '4',
               memory: '4096',
               primary_disk_size: '100'
             }
           end

    main_params.merge(type)
  end

  def main_params
    {
        hypervisor_id: hypervisor.id,
        template_id: (template.id if defined?(template.id)),
        label: "qa_ant-cdn-#{template.label}",
        memory: template.min_memory_size,
        cpus: '1',
        primary_disk_size: template.min_disk_size,
        required_virtual_machine_build: '1',
        required_ip_address_assignment: '1',
        rate_limit: '0',
        required_virtual_machine_startup: '1',
        cpu_shares: ('1' if !(hypervisor_type == 'kvm' && hypervisor.distro == 'centos5')),
        # swap_disk_size: ('1' if template.allowed_swap),
    }
  end

  def info_update(data=nil)
    data ||= interface.get(route)
    data.edge_server.each { |k,v| instance_variable_set("@#{k}", v) } if CDN_SERVER == 'edge_server'
    data.storage_server.each { |k,v| instance_variable_set("@#{k}", v) } if CDN_SERVER == 'storage_server'
    data.accelerator.each { |k,v| instance_variable_set("@#{k}", v) } if CDN_SERVER == 'accelerator'
    interface.hypervisor ||= Hypervisor.new(interface).find_by_id(hypervisor_id)
    interface.template ||= ImageTemplate.new(interface).find_by_id(template_id)
    disks
    network_interfaces
    self
  end

  def locked?
    interface.get(route).virtual_machine.locked
  end

  def all
    interface.get("/#{CDN_SERVER}s").map &CDN_SERVER.to_sym
  end

  def rebuild(image: template, required_startup: 1)
    params = {
        ENV['CDN_SERVER'] => {
            template_id: image.id,
            required_startup: required_startup.to_s,
            # licensing_type: build_params[:licensing_type]
        }
    }
    response = interface.post("#{route}/build", params)
    return response if api_response_code  == '422'
    wait_for_build(image: image, require_startup: !required_startup.zero?, rebuild: true)
  end

  def rerun_cdn_scripts
    interface.post("#{route}/rerun_creation_scripts")
    wait_for_create_cdn_server
  end

  def edit_cpus(**kwargs)
    #TODO Andrii, edit_cpus and edit should be the single method
    interface.put(route, {ENV['CDN_SERVER'] => kwargs})
    wait_for_resize
    info_update
  end

  def edit_market_place_status
    if add_to_marketplace == true
      interface.put(route, {add_to_marketplace: 0})
    else
      interface.put(route, {add_to_marketplace: 1})
    end
    info_update
  end

  def route
    "/#{CDN_SERVER}s/#{identifier}"
  end

  def add_note(**params)
    interface.put(route, {ENV['CDN_SERVER'] => params})
    info_update
  end

  def destroy_note(type)
    interface.delete("#{route}/note", {type: "#{type}"})
    info_update
  end
end

#TODO update_os should be failed
#create some 'if' for swap disk in wait_for_build method and crate ticket like swap disk is forbidden for cdn servers but is allowing by template
#update_firewall_rules should be failed
#boot_from_cd should be failed
#can_be_booted_from_iso?/boot_from_iso/reboot_from_iso should be failed
#autobackup/create_backup/get_backups should be failed for es/acc only
#recipe should be failed
#autoscale should be failed
#reset_root_password should be = 422
#set_ssh_keys should be = 422
#add segregate/desegregate
#add migrate
#add rebuild