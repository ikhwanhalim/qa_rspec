require_relative 'transaction'

module TemplateManager
  include Transaction

  attr_reader :template_store

  def get_template(manager_id)
    Log.error('Template manager_id is empty') unless manager_id
    @manager_id = manager_id
    template = download_template
    Log.error('Template does not exist') unless template
    wait_for_download_template(template.id) if template.state != 'active'
    add_to_template_store(template.id)
    template
  end

  def get_inactive
    interface.get('/templates/inactive')
  end

  def get_available
    interface.get('/templates/available')
  end

  def get_installed
    interface.get('/templates/all')
  end

  def get_installs
    interface.get('/templates/installs')
  end

  def download_template
    inactive = get_inactive.select { |t| t['image_template']['manager_id'] == @manager_id}
    available = get_available.select { |t| t['remote_template']['manager_id'] == @manager_id }
    installed = get_installed.select { |t| t['image_template']['manager_id'] == @manager_id }
    if inactive.any?
      interface.post("/templates/installs/#{inactive.first['image_template']['id']}/restart")['image_template']
    elsif installed.any?
      installed.max_by { |t| t['image_template']['version'].to_f }['image_template']
    elsif available.any?
      interface.post("/templates", {'image_template' => {'manager_id' => @manager_id}})['image_template']
    end
  end

  def add_to_template_store(template_id, price=0)
    data = {"relation_group_template"=>{"template_id"=>template_id, "price"=>price}}
    @template_store = interface.get("/template_store").detect do |s|
      !s.system_group && (s.relations.any? ? !s.relations.first.image_template.remote_id : true)
    end
    @template_store ||= interface.post("/settings/image_template_groups", {"image_template_group"=>{"label"=>"AutoTests"}})
    interface.post("/settings/image_template_groups/#{@template_store['id']}/relation_group_templates", data)
  end

  def wait_for_download_template(id)
    wait_for_transaction(id, "ImageTemplateBase", "download_template")
    wait_for_transaction(id, "ImageTemplateBase", "test_checksum")
    wait_for_transaction(id, "ImageTemplateBase", "distribute_template")
    wait_for_transaction(id, "ImageTemplateBase", "cleanup_template")
  end
end

