require 'yaml'
require_relative 'onapp_http'

module Hypervisor
  def for_vm_creation(virt, hvz_id = nil)
    max_free = 0
    hv = nil
    virtualization = 'xen' if virt == 'xen3' or virt == 'xen4'
    virtualization = 'kvm' if virt == 'kvm5' or virt == 'kvm6'

    distro = 'centos5' if virt == 'xen3' or virt == 'kvm5'
    distro = 'centos6' if virt == 'xen4' or virt == 'kvm6'
    data = get("/hypervisors").map {|x| x['hypervisor']}
    data.each do |x|
      if max_free < x['free_mem'] and x['distro'] == distro and x['hypervisor_type'] == virtualization and
          x['enabled'] and x['server_type'] == 'virtual' and x['online']
        if hvz_id
          hv = x if hvz_id == x['hypervisor_group_id']
        else
          hv = x
        end
        max_free = x['free_mem']
      end
    end
    return hv
  end
end