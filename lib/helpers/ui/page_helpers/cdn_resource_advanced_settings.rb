#require 'helpers/ui_helpers'
require 'selenium-webdriver'
require 'page-object'

module CdnResourceAdvancedSettings
  include UiHelpers
  include PageObject
  attr_accessor :origin_policy, :country_access_policy, :except_for_countries, :hotlink_policy, :except_for_domains,
                :ip_access_policy, :except_for_ip, :secondary_cdn_hostnames, :enable_url_signing, :url_signing_key,
                :cache_expiry, :enable_password, :unauthorized_html, :credentials, :enable_mp4_pseudo_streaming, :enable_flv_pseudo_streaming,
                :ignore_set_cookie, :limit_rate, :limit_rate_after, :proxy_read_time_out, :proxy_connect_time_out, :proxy_cache_key,
                :block_search_engine_crawlers



  text_area(:cdn_resource_domains, :id => 'cdn_resource_domains')
  text_area(:cdn_resource_ip_addresses, :id => 'cdn_resource_ip_addresses')
  text_field(:cdn_resource_url_signing_key, :id => 'cdn_resource_url_signing_key')
  text_field(:cdn_resource_cache_expiry, :id => 'cdn_resource_cache_expiry')
  text_area(:cdn_resource_password_unauthorized_html, :id => 'cdn_resource_password_unauthorized_html')
  text_field(:cdn_resource_limit_rate, :id => 'cdn_resource_limit_rate')
  text_field(:cdn_resource_limit_rate_after, :id => 'cdn_resource_limit_rate_after')
  text_field(:cdn_resource_proxy_read_time_out, :id => 'cdn_resource_proxy_read_time_out')
  text_field(:cdn_resource_proxy_connect_time_out, :id => 'cdn_resource_proxy_connect_time_out')

  def origin_policy=(value)
    select_box('cdn_resource_origin_policy_chzn', value) if value
  end
  def country_access_policy=(value)
    select_box('cdn_resource_country_access_policy_chzn', value) if value
  end
  def except_for_countries=(value)
    multi_select_box('cdn_resource_countries_chzn', value) if value
  end
  def hotlink_policy=(value)
    select_box('cdn_resource_hotlink_policy_chzn', value) if value
  end
  def except_for_domains=(value)
    self.cdn_resource_domains = value
  end
  def ip_access_policy=(value)
    select_box('cdn_resource_ip_access_policy_chzn', value) if value
  end
  def except_for_ip=(value)
    self.cdn_resource_ip_addresses = value if value
  end
  def secondary_cdn_hostnames=(value)
    list = value.kind_of?(Array) ? value : [value]
    list.each_with_index do |origin, index|
      break if index == list.count - 1
        browser.find_elements(:xpath => "//ul[@id = 'multiply-field']/li[#{index}]//span[@class='icon add']").first.click() if index > 0
        browser.find_elements(:xpath => "//ul[@id = 'multiply-field']/li[#{index+1}]//input[@name='cdn_resource[secondary_hostnames][]']").first.send_keys(origin)
      end if list.any?
  end
  def enable_url_signing=(value)
    self.slide_check_box('urlsign_checkbox', value) unless value.nil?
  end
  def url_signing_key=(value)
    self.cdn_resource_url_signing_key=value if value
  end
  def cache_expiry=(value)
    self.cdn_resource_cache_expiry=value if value
  end
  def enable_password=(value)
    slide_check_box('password_checkbox', value) unless value.nil?
  end
  def unauthorized_html=(value)
    self.cdn_resource_password_unauthorized_html if value
  end
  def credentials=(value)
    list = value.kind_of?(Array) ? value : [value]
    list.each_with_index do |cred, index|
      break if index == list.count
      browser.find_elements(:xpath => "//a[@id='add-credentials-btn']").first.click()
      cred = cred.split(' ')
      wait_for_ajax
      browser.find_elements(:xpath => "//tr[#{index+2}]//input[@name = 'cdn_resource[form_pass][user][]']").first.send_keys(cred[0])
      browser.find_elements(:xpath => "//tr[#{index+2}]//input[@name = 'cdn_resource[form_pass][pass][]']").first.send_keys(cred[1])
    end if list.any?
  end
  def enable_mp4_pseudo_streaming=(value)
    slide_check_box('mp4_pseudo_checkbox', value) unless value.nil?
  end
  def enable_flv_pseudo_streaming=(value)
    slide_check_box('flv_pseudo_checkbox', value) unless value.nil?
  end
  def ignore_set_cookie=(value)
    slide_check_box('ignore_set_cookie_checkbox', value) unless value.nil?
  end
  def limit_rate=(value)
    self.cdn_resource_limit_rate = value if value
  end
  def limit_rate_after=(value)
    self.cdn_resource_limit_rate_after = value if value
  end
  def proxy_read_time_out=(value)
    self.cdn_resource_proxy_read_time_out = value if value
  end
  def proxy_connect_time_out=(value)
    self.cdn_resource_proxy_connect_time_out = value if value
  end
  def proxy_cache_key=(value)
    select_box('cdn_resource_proxy_cache_key_chzn', value) if value
  end
  def block_search_engine_crawlers=(value)
    slide_check_box('http_bot_blocked_checkbox', value) unless value.nil?
  end

  # TODO Add missed fields for 'vod' and 'live streaming' resource types when they will be fixed ('Enable Secure Wowza' and 'Enable Token Authentication' with child elements)
end