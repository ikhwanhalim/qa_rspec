require 'yaml'
require_relative 'onapp_http'

module Hypervisor
  private
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
  def hv_for_vm_migration
    hypervisors = get("/hypervisors").map {|x| x['hypervisor']}
    hypervisors.select! do |hv|
      hv['hypervisor_group_id'] == @hypervisor['hypervisor_group_id'] &&
      hv['hypervisor_type'] == @hypervisor['hypervisor_type'] &&
      hv['distro'] == @hypervisor['distro'] &&
      hv['id'] != @hypervisor['id'] &&
      hv['online'] && hv['enabled'] &&
      hv['free_memory'] > memory
    end
    hypervisors.first
  end
end