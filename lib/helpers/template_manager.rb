require 'helpers/ssh'

module TemplateManager

  def get_template(file_name)
    @file_name = file_name
    template = installed_template.nil? ? download_template : installed_template
    if template.nil?
      raise 'Template does not exist'
    else
      add_to_template_store(template['id'])
      return template
    end
  end

  def installed_template
    templates = get(@url + "/templates.json").select {|t| t['image_template']['file_name'] == @file_name}
    if templates.any?
      return templates.first['image_template']
    else
      return nil
    end
  end

  def download_template
    templates = get(@url + "/templates/available.json").select {|t| t['remote_template']['file_name'] == @file_name}
    if templates.any?
      id = templates.first['remote_template']['manager_id']
      return post(@url + "/templates.json", {'image_template'=>{'manager_id'=>id}})["image_template"]
    else
      return nil
    end
  end

  def add_to_template_store(template_id, price=0)
    data = {"relation_group_template"=>{"template_id"=>template_id, "price"=>price}}
    template_store_list = get(@url + "/template_store.json")
    if template_store_list.any?
      template_store = template_store_list.first
    else
      template_store = post(@url + "/settings/image_template_groups.json", {"image_template_group"=>{"label"=>"AutoTests"}})
    end
    post(@url + "/settings/image_template_groups/#{template_store['id']}/relation_group_templates.json", data)
  end

  def remove_template(id)
    delete(@url + "/templates/#{id}.json")
  end

  def exist_on_server?
    Ssh.execute_with_keys(@ip, 'ls /onapp/templates').split("\n").include? @file_name
  end
end

