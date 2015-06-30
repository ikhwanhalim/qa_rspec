require 'yaml'
require 'page-object'
require 'selenium-webdriver'
require 'helpers/ui_helpers'

module DetailCdnResourcePage
  class Basic
    include PageObject
    include UiHelpers

    PageObject.javascript_framework = :jquery
    label(:owner, xpath: "//*[contains(text(), 'Owner')]/..//a")
    a(:owner_link, xpath: "//*[contains(text(), 'Owner')]/..//a")
    label(:cdn_hostname, xpath: "//*[contains(text(), 'CDN hostname')]/../*[2]")
    label(:resource_type, xpath: "//*[contains(text(), 'Resource type')]/../*[2]")
    label(:ssl_on, xpath: "//*[contains(text(), 'SSL On')]/../*[2]")
    label(:sni_ssl_certificate, xpath: "//*[contains(text(), 'SNI SSL Certificate')]/../*[2]")
    label(:cdn_reference, xpath: "//*[contains(text(), 'CDN reference')]/../*[2]")
    label(:resource_status, xpath: "//*[contains(text(), 'Resource Status')]/../*[2]")
    a(:resource_status_link, xpath: "//*[contains(text(), 'Resource Status')]/..//a")
    table(:origins, xpath: "//legend[contains(text(), 'Origins')]/../table")
    div(:dns_settings, xpath: "//legend[contains(text(), 'DNS Settings')]/..")
    table(:edge_groups, xpath: "//legend[contains(text(), 'Edge Groups')]/..")

    def initialize(browser, visit=true)
      url_status = browser.current_url =~ /http(s)?:\/\/\S+\/cdn_resources\/\d+$/
      fail 'Wrong page URL' if url_status != 0
      self.class.page_url(browser.current_url)
      super
    end
  end

  class Advanced
    include PageObject
    include UiHelpers

    PageObject.javascript_framework = :jquery
    label(:publisher_name, xpath: "//*[contains(text(), 'Publisher name')]/../*[2]")
    label(:country_access_policy, xpath: "//*[contains(text(), 'Country Access Policy')]/../*[2]")
    label(:hotlink_policy, xpath: "//*[contains(text(), 'Hotlink Policy')]/../*[2]")
    label(:ip_access_policy, xpath: "//*[contains(text(), 'IP Access Policy')]/../*[2]")
    label(:password_on, xpath: "//*[contains(text(), 'Password On')]/../*[2]")
    label(:mp4_pseudo_streaming, xpath: "//*[contains(text(), 'MP4 Pseudo Streaming')]/../*[2]")
    label(:flv_pseudo_streaming, xpath: "//*[contains(text(), 'FLV Pseudo Streaming')]/../*[2]")
    label(:url_signing_enabled, xpath: "//*[contains(text(), 'URL Signing Enabled')]/../*[2]")
    label(:limit_rate, xpath: "//*[contains(text(), 'Limit rate')]/../*[2]")
    label(:limit_rate_after, xpath: "//*[contains(text(), 'Limit rate after')]/../*[2]")
    label(:origin_policy, xpath: "//*[contains(text(), 'Origin Policy')]/../*[2]")
    label(:cache_expiry, xpath: "//*[contains(text(), 'Cache Expiry')]/../*[2]")
    label(:ignore_set_cookie, xpath: "//*[contains(text(), 'Ignore Set-Cookie')]/../*[2]")
    label(:block_search_engine_crawlers, xpath: "//*[contains(text(), 'Block search engine crawlers')]/../*[2]")
    label(:proxy_cache_key, xpath: "//*[contains(text(), 'Proxy cache key')]/../*[2]")
    label(:proxy_read_time_out, xpath: "//*[contains(text(), 'Proxy read time out')]/../*[2]")
    label(:proxy_connect_time_out, xpath: "//*[contains(text(), 'Proxy connect time out ')]/../*[2]")

    def initialize(browser, visit=true)
      url_status = browser.current_url =~ /http(s)?:\/\/\S+\/cdn_resources\/\d+$/
      fail 'Wrong page URL' if url_status != 0
      self.class.page_url(browser.current_url + '/advanced')
      super
    end
  end
end