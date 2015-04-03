class Template < ActiveRecord::Base
  include OnappHTTP
  include TemplateManager
  attr_accessible :label, :manager_id, :virtualization

  def update_templates
    onapp_http_auth
    templates = []
    array = []
    templates += installed_templates
    templates += available_templates
    exists_templates = Template.all.map {|t| t.manager_id}
    keys = ["label", "manager_id", "virtualization"]

    templates.each do |t|
      unless exists_templates.include?(t["manager_id"])
        hash = Hash[[keys,[t['label'], t['manager_id'], t['virtualization']]].transpose]
        array << Template.new(hash)
      end
    end

    Template.transaction do
      Template.import array
    end
  end

  def download_templates(manager_ids)
    onapp_http_auth
    manager_ids.each do |id|
      Spawnling.new do
        template = Template.where(manager_id: id).first
        template.update_attribute(:status, 'Undefined')
        get_template(id)
        template.update_attribute(:status, 'Downloaded')
      end
    end
  end

  def onapp_http_auth
    data = YAML::load_file('config/conf.yml')
    auth(url: data['url'], user: data['user'], pass: data['pass'])
  end
end
