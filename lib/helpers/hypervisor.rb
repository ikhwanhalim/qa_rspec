require 'yaml'
module Hypervisor
  def for_vm_creation(virt)
    max_free = 0
    hv = nil
    virtualization = 'xen' if virt == 'xen3' or virt == 'xen4'
    virtualization = 'kvm' if virt == 'kvm5' or virt == 'kvm6'

    distro = 'centos5' if virt == 'xen3' or virt == 'kvm5'
    distro = 'centos6' if virt == 'xen4' or virt == 'kvm6'
    data = get("#{@url}/hypervisors.json")
    data.each do |x|
      if x['hypervisor']['distro'] == distro and x['hypervisor']['hypervisor_type'] == virtualization
        hv = x['hypervisor'] if max_free < x['hypervisor']['free_mem'] and x['hypervisor']['enabled'] and x['hypervisor']['server_type'] == 'virtual'
        max_free = x['hypervisor']['free_mem'] if max_free < x['hypervisor']['free_mem'] and x['hypervisor']['enabled'] and x['hypervisor']['server_type'] == 'virtual'
      end
    end
    return hv
  end
end