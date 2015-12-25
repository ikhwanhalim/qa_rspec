class Iso
  include Transaction
  attr_reader :interface, :errors, :id, :label, :min_memory_size, :version, :operating_system, :operating_system_distro,
              :virtualization, :user_id

  def initialize(interface)
    @interface = interface
  end

  def build_data
    {
      label: @label || "ISO-#{SecureRandom.hex(4)}",
      make_public: '0',
      min_memory_size: '256',
      version: '1.0',
      operating_system: 'Linux',
      operating_system_distro: 'Fedora',
      virtualization: ["xen", "kvm"],
      file_url: 'http://templates.repo.onapp.com/Linux-iso/Fedora-Server-netinst-x86_64-21.iso'
    }
  end

  def create(**params)
    response = interface.post("/template_isos", { image_template_iso: build_data.merge(params) })
    response_handler response
    wait_for_downloading unless response['errors']
  end

  def edit(**params)
    response = interface.put("/template_isos/#{id}", { image_template_iso: build_data.merge(params) })
    response_handler response
  end

  def make_public
    interface.post("/template_isos/#{id}/make_public")
  end

  def find(iso_id)
    response = interface.get("/template_isos/#{iso_id}")
    response_handler response
  end

  def remove
    interface.delete("/template_isos/#{id}")
    if api_response_code != '204'
      Log.error('ISO has not been deleted')
      return false
    end
    wait_for_removing
  end

  def wait_for_downloading
    wait_for_transaction(id, 'ImageTemplateBase', 'download_iso')
  end

  def wait_for_removing
    wait_for_transaction(id, 'ImageTemplateBase', 'destroy_iso')
  end

  def api_response_code
    interface.conn.page.code
  end

  private

  def response_handler(response)
    @errors = response['errors']
    if response['image_template_iso']
      response['image_template_iso'].each { |k, v| instance_variable_set("@#{k}", v)}
    else
      Log.warn(@errors)
      false
    end
  end
end