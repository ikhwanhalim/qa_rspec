class IsoActions
  include ApiClient, Log

  attr_reader :iso

  def precondition
    @iso = Iso.new(self)
    @iso.create

    self
  end
end