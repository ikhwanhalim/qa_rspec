class CdnReportingActions
  include ApiClient, Log

  attr_reader :cdn_reporting

  def precondition
    @cdn_reporting = CdnReporting.new(self)

    self
  end
end