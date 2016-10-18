class InstancePackageActions
  include ApiClient, Log

  attr_reader :instance_package

  def precondition
    @instance_package = InstancePackage.new(self)
    @instance_package.create

    self
  end
end