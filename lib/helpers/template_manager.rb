require_relative 'onapp_http'

module TemplateManager
  attr_reader :template_store, :template

  def get_template(manager_id)
    Log.error('Template manager_id is empty') unless manager_id
    @manager_id = manager_id
    @template = installed_template.nil? ? download_template : installed_template
    if @template.nil?
      raise 'Template does not exist'
    else
      sleep 20 until active? @template['id']
      add_to_template_store(@template['id'])
      return @template
    end
  end

  def installed_templates
    get("/templates/all").map {|t| t['image_template']}
  end

  def available_templates
    get("/templates/available").map {|t| t['remote_template']}
  end

  private

  def installed_template
    templates = get("/templates/all").select {|t| t['image_template']['manager_id'] == @manager_id}
    if templates.any?
      return templates.first['image_template']
    else
      return nil
    end
  end

  def download_template
    templates = get("/templates/available").select {|t| t['remote_template']['manager_id'] == @manager_id}
    for_upgrade = get("/templates/upgrades").select {|t| t['remote_template']['manager_id'] == @manager_id}
    if templates.any?
      return post( "/templates", {'image_template'=>{'manager_id'=>@manager_id}})["image_template"]
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
      !s['system_group'] && !s['relations'].first['image_template']['remote_id'] if s['relations'].any?
    end
    if template_store_list
      @template_store = template_store_list.first
    else
      @template_store = post("/settings/image_template_groups", {"image_template_group"=>{"label"=>"AutoTests"}})
    end
    post("/settings/image_template_groups/#{@template_store['id']}/relation_group_templates", data)
  end

  def active?(id)
    @template = get("/templates/#{id}").values.first
    @template['state'] == 'active'
  end

  def remove_template(id)
    delete("/templates/#{id}")
  end
end

