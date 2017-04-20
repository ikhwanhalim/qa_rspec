class CdnResourceActions
  include ApiClient, Log

  attr_reader :cdn_resource

  def precondition
    @cdn_resource = CdnResource.new(self)

    self
  end
end