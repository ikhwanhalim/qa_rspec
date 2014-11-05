require 'helpers/hypervisor'
require 'helpers/ssh'

module TemplateManager

  def get_template(file_name, virt)
    @file_name = file_name
    @virt = virt
    template = installed_template.nil? ? download_template : installed_template
    if template.nil?
      raise 'Template does not exist'
    else
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
      return post(@url + "/templates?image_template%5Bmanager_id%5D=#{id}")["image_template"]
    else
      return nil
    end
  end

  def remove_template(id)
    delete(@url + "/templates/#{id}.json")
  end

  def exist_on_server?
    Ssh.execute_with_keys(@ip, 'ls /onapp/templates').split("\n").include? @file_name
  end
end

