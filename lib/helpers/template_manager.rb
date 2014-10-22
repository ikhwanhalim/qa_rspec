require_relative 'onapp_http'

module TemplateManager
  include OnappHTTP

  def get_available
    get("#{@ip}/templates/available.json")
  end

  def get_all
    result = get("#{@ip}/templates/all.json")
    result.map {|t| t["image_template"]["manager_id"]}
  end

  def download(id)
    data = {image_template: {manager_id: id}}
    post("#{@ip}/templates.json", data) unless get_all.include?(id)
  end
end