require_relative 'api_client'
require_relative 'transaction'

module TemplateManager
  include Transaction

  attr_reader :template_store

  def get_template(manager_id)
    Log.error('Template manager_id is empty') unless manager_id
    @manager_id = manager_id
    template = installed_template || download_template
    Log.error('Template does not exist') unless template
    wait_for_download_template(template.id) if template.state != 'active'
    add_to_template_store(template.id)
    template
  end

  def installed_templates
    get("/templates/all").map {|t| t['image_template'] if t['image_template']['manager_id']}.compact
  end

  def available_templates
    get("/templates/available").map {|t| t['remote_template']}
  end

  def dev_templates
    templates = get_from_url('http://templates-manager.onappdev.com/')
    templates.map { |t| t.release.label += '(dev)'; t.release }
  end

  def released_templates
    templates = get_from_url('http://templates-manager.onapp.com/')
    templates.map &:release
  end

  def installed_template
    templates = get("/templates/all").select { |t| t['image_template']['manager_id'] == @manager_id }
    if templates.any?
      return templates.first['image_template']
    else
      return nil
    end
  end

  def download_template
    templates = get("/templates/available").select { |t| t['remote_template']['manager_id'] == @manager_id }
    for_upgrade = get("/templates/upgrades").select { |t| t['remote_template']['manager_id'] == @manager_id }
    if templates.any?
      return post( "/templates", {'image_template' => {'manager_id' => @manager_id}})["image_template"]
    elsif for_upgrade.any?
      id = for_upgrade.first['remote_template']['id']
      return put("/templates/#{id}/upgrade")["image_template"]
    else
      return nil
    end
  end

  def add_to_template_store(template_id, price=0)
    data = {"relation_group_template"=>{"template_id"=>template_id, "price"=>price}}
    template_store_list = get("/template_store").select do |s|
      !s.system_group && (s.relations.any? ? !s.relations.first.image_template.remote_id : true)
    end
    if template_store_list
      @template_store = template_store_list.first
    else
      @template_store = post("/settings/image_template_groups", {"image_template_group"=>{"label"=>"AutoTests"}})
    end
    post("/settings/image_template_groups/#{@template_store['id']}/relation_group_templates", data)
  end

  def wait_for_download_template(id)
    wait_for_transaction(id, "ImageTemplateBase", "download_template")
    wait_for_transaction(id, "ImageTemplateBase", "test_checksum")
    wait_for_transaction(id, "ImageTemplateBase", "distribute_template")
    wait_for_transaction(id, "ImageTemplateBase", "cleanup_template")
  end

  def remove_template(id)
    delete("/templates/#{id}")
  end
end

