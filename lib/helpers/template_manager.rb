require_relative 'curl'

module TemplateManager
  include Curl
  include Parser
  attr_accessor :template

  def get_available
    from_api get("/templates/available")
  end

  def get_all
    result = from_api get("/templates/all")
    result.map {|t| t["image_template"]["manager_id"]}
  end

  def download(id)
    data = {image_template: {manager_id: id}}
    @template = get_hash_with_split(post("/templates", data.to_json), "image_template") unless get_all.include?(id)
  end
end