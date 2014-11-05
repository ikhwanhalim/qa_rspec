require 'helpers/onapp_http'
require 'yaml'
class Hypervisor
  class << self
    include OnappHTTP
    def for_vm_creation(virt)      
      max_free = 0
      hv_id = nil
      virtualization = 'xen' if virt == 'xen3' or virt == 'xen4'
      virtualization = 'kvm' if virt == 'kvm5' or virt == 'kvm6'
      
      distro = 'centos5' if virt == 'xen3' or virt == 'kvm5'
      distro = 'centos6' if virt == 'xen4' or virt == 'kvm6'
    
      data = YAML::load_file('config/conf.yml')
      url = data['ip']
      auth "#{url}/users/sign_in", data['login'], data['password']
      data = get("#{url}/hypervisors.json")
      data.each do |x|        
        if x['hypervisor']['distro'] == distro and x['hypervisor']['hypervisor_type'] == virtualization          
          hv_id = x['hypervisor']['id'] if max_free < x['hypervisor']['free_mem'] and x['hypervisor']['enabled'] and x['hypervisor']['server_type'] == 'virtual'
          max_free = x['hypervisor']['free_mem'] if max_free < x['hypervisor']['free_mem'] and x['hypervisor']['enabled'] and x['hypervisor']['server_type'] == 'virtual'
        end
      end
      return hv_id                  
    end
  end
end