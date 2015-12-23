require_relative 'remote_methods.rb'

class VirtualMachine
  include RemoteMethods
  attr_reader :hypervisor, :template

  def build_params
    {
      virtual_machine: {
        hypervisor_id: '5',
        template_id: '137',
        label: 'auto.test',
        memory: '128',
        cpus: '1',
        primary_disk_size: '5',
        hostname: 'auto.test',
        required_ip_address_assignment: '1',
        required_virtual_machine_startup: '1',
        cpu_shares: '1',
        required_virtual_machine_build: '1',
        swap_disk_size: '1'
      }
    }
  end
end