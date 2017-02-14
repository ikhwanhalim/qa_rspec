require './lib/hypervisor'
class VCenter < Hypervisor

  def find_by_virt(hvz_id = nil)
    max_free = 0
    hv = nil
    interface.get('/hypervisors').map(&:hypervisor).each do |h|
      if max_free < h.free_memory && h.hypervisor_type == 'vcenter' &&
          h.enabled && h.server_type == 'virtual' && h.online && h.label !~ /fake/i
        hv = hvz_id ? (h if hvz_id == h.hypervisor_group_id) : h
        max_free = h.free_memory
      end
    end
    hv ? info_update(hv) : Log.error('vCenter was not found')
    Log.info("vCenter with id #{hv.id} has been selected")
    self
  end
end