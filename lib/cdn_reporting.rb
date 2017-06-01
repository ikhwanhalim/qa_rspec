class CdnReporting

  attr_reader :interface

  def initialize(interface)
    @interface = interface
  end

  def route_cdn_reporting
    '/cdn/reports'
  end

  def route_reporting_overview
    "#{route_cdn_reporting}/overview"
  end

  def route_reporting_cache_statistics
    "#{route_cdn_reporting}/cache_statistics"
  end

  def route_reporting_top_files
    "#{route_cdn_reporting}/top_files"
  end

  def route_reporting_top_referrers
    "#{route_cdn_reporting}/top_referrers"
  end

  def route_reporting_status_codes
    "#{route_cdn_reporting}/status_codes"
  end

  def route_reporting_visitors
    "#{route_cdn_reporting}/visitors"
  end

  def route_reporting_stream_bandwidth
    "#{route_cdn_reporting}/bandwidth_statistics"
  end

  def route_reporting_concurrent_statistics
    "#{route_cdn_reporting}/concurrent_statistics"
  end

  def route_reporting_admin
    "#{route_cdn_reporting}/admin"
  end

  def route_reporting_top_50_cdn_resources
    "#{route_reporting_admin}/top_50_cdn_resources"
  end

  def route_reporting_locations
    "#{route_reporting_admin}/locations"
  end

  def route_reporting_top_50_http_errors
    "#{route_reporting_admin}/top_50_http_errors"
  end
end