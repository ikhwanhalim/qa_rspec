module TemplateManager
  attr_reader :template_store

  def get_template(manager_id)
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

  private

  def installed_template
    templates = get(@url + "/templates/all.json").select {|t| t['image_template']['manager_id'] == @manager_id}
    if templates.any?
      return templates.first['image_template']
    else
      return nil
    end
  end

  def download_template
    templates = get(@url + "/templates/available.json").select {|t| t['remote_template']['manager_id'] == @manager_id}
    for_upgrade = get(@url + "/templates/upgrades.json").select {|t| t['remote_template']['manager_id'] == @manager_id}
    if templates.any?
      return post(@url + "/templates.json", {'image_template'=>{'manager_id'=>@manager_id}})["image_template"]
    elsif for_upgrade.any?
      id = for_upgrade.first['remote_template']['id']
      return put(@url + "/templates/#{id}/upgrade.json")["image_template"]
    else
      return nil
    end
  end

  def add_to_template_store(template_id, price=0)
    data = {"relation_group_template"=>{"template_id"=>template_id, "price"=>price}}
    template_store_list = get(@url + "/template_store.json").select {|s| s['system_group'] == false}
    if template_store_list
      @template_store = template_store_list.first
    else
      @template_store = post(@url + "/settings/image_template_groups.json", {"image_template_group"=>{"label"=>"AutoTests"}})
    end
    post(@url + "/settings/image_template_groups/#{@template_store['id']}/relation_group_templates.json", data)
  end

  def active?(id)
    @template = get(@url + "/templates/#{id}.json").values.first
    @template['state'] == 'active'
  end

  def remove_template(id)
    delete(@url + "/templates/#{id}.json")
  end
end

