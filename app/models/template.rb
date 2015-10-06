class Template < ActiveRecord::Base
  include ApiClient
  include TemplateManager
  attr_accessible :label, :manager_id, :virtualization, :version

  scope :dev, ->(id = nil) do
    query = id ? "manager_id = '#{id}' AND " : ''
    where(query + "label LIKE '%(dev)%'").order(:label)
  end

  scope :prod, ->(id = nil) do
    query = id ? "manager_id = '#{id}' AND " : ''
    where(query + "label NOT LIKE '%(dev)%'").order(:label)
  end

  def update_templates
    templates = released_templates + dev_templates
    array = []
    exists_templates = Template.all.map {|t| "#{t.manager_id}.#{t.version}"}
    keys = ['label', 'manager_id', 'virtualization', 'version']
    templates.each do |t|
      unless exists_templates.include?("#{t.manager_id}.#{t.version}")
        hash = Hash[[keys,[t['label'], t['manager_id'], t['virtualization'], t['version']]].transpose]
        array << Template.new(hash)
      end
    end
    Template.transaction do
      Template.import array
    end
  end

  def server_url
    onapp_http_auth
    get('/settings/edit').settings.update_server_url
  end

  def self.env_list(manager_id = nil)
    Template.new.server_url.include?('onappdev') ? self.dev(manager_id) : self.prod(manager_id)
  end

  def download_templates(manager_ids)
    onapp_http_auth
    manager_ids.each do |id|
      Spawnling.new do
        template = Template.env_list(id).first
        template.update_attribute(:status, 'Undefined')
        get_template(id)
        template.update_attribute(:status, 'Downloaded')
      end
    end
  end

  def set_undefined(templates)
    onapp_http_auth
    installed_manager_ids = installed_templates.map &:manager_id
    templates.each do |t|
      t.update_attribute(:status, 'Undefined') unless installed_manager_ids.include?(t.manager_id)
    end
  end

  def onapp_http_auth
    data = YAML::load_file('config/conf.yml')
    auth(url: data['url'], user: data['user'], pass: data['pass'])
  end
end
