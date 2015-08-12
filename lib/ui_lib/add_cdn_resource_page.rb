require 'yaml'
require 'page-object'
require 'selenium-webdriver'
require 'helpers/ui_helpers'
require 'helpers/ui/page_helpers/cdn_resource_advanced_settings'
require 'ui_lib/detail_cdn_resource_page'

class AddCdnResourcePage
  include PageObject
  include UiHelpers
  include CdnResourceAdvancedSettings
  include DetailCdnResourcePage

  attr_accessor :cdn_resource_type, :cdn_hostname, :enable_ssl, :ssl_type, :custom_sni_ssl, :content_origin,
                :storage_server_origin, :ftp_password, :ftp_password_confirmation, :resource_origin, :external_publishing_location, :failover_external_publishing_location,
                :edge_groups, :internal_publishing_location,
                :failover_internal_publishing_location, :publishing_point

  PageObject.javascript_framework = :jquery


  page_url "#{YAML::load_file('config/conf.yml')['url']}/cdn_resources/new"

  checkbox(:http, :id => 'cdn_resource_resource_type_http_pull')
  checkbox(:vod, :id => 'cdn_resource_resource_type_stream_vod_pull')
  checkbox(:live_streaming, :id => 'cdn_resource_resource_type_stream_live')

  text_field(:cdn_host, :id => 'cdn_resource_cdn_hostname')
  text_field(:ftp_pass, :id => 'cdn_resource_ftp_password')
  text_field(:ftp_pass_confirmation, :id => 'cdn_resource_ftp_password_confirmation')

  text_field(:external_publishing_loc, :id => 'cdn_resource_external_publishing_location')
  text_field(:failover_external_publishing_loc, :id => 'cdn_resource_failover_external_publishing_location')
  checkbox(:shared_ssl, :id => 'cdn_resource_ssl_type_ssl_on')
  checkbox(:custom_sni_ssl, :id => 'cdn_resource_ssl_type_ssl')

  button(:next_button, :xpath => "//button[@class = 'round-button next']")
  button(:create_cdn_resource, :xpath => "//button[@type = 'submit']")

  def cdn_resource_type=(value)
    case value
      when 'http'
        @resource_type ='http'
        check_http
      when 'vod'
        @resource_type ='vod'
        check_vod
      when 'live_streaming'
        check_live_streaming
      else
        raise "Unknown CDN resource type: #{value}"
    end if value
  end

  def cdn_hostname=(value)
    self.cdn_host = value if value
  end

  def enable_ssl=(value)
    slide_check_box('enable_ssl_checkbox', value) unless value.nil?
  end

  def ssl_type=(value)
    case value
      when 'shared'
        check_shared_ssl
      when 'custom'
        check_custom_sni_ssl
      else
        raise "Unknown SSL type: #{value}"
    end if value
  end

  def custom_sni_ssl=(value)
    select_box('cdn_resource_content_origin_chzn', value) if value
  end

  def content_origin=(value)
    select_box('cdn_resource_content_origin_chzn', value) if value
  end

  def storage_server_origin=(value)
    select_box('cdn_resource_storage_server_location_chzn', value) if value
  end

  def ftp_password=(value)
    self.ftp_pass = value if value
  end

  def ftp_password_confirmation=(value)
    self.ftp_pass_confirmation = value if value
  end

  def resource_origin=(value)
    if @resource_type == 'http' then
        list = value.kind_of?(Array) ? value : [value]
        list.each_with_index do |origin, index|
          break if index == list.count
          browser.find_elements(:xpath => "//ul[@id = 'origins-multiply-field']/li[#{index}]//span[@class='icon add']").first.click() if index > 0
          browser.find_elements(:xpath => "//ul[@id = 'origins-multiply-field']/li[#{index+1}]//input[@name='cdn_resource[origins][]']").first.send_keys(origin)
        end
    elsif @resource_type == 'vod'
      browser.find_elements(:id => 'cdn_resource_origin').first.send_keys(value)
    end if value
  end

  def external_publishing_location=(value)
    self.external_publishing_loc = value if value
  end

  def failover_external_publishing_location=(value)
    self.failover_external_publishing_loc = value if value
  end

  def edge_groups=(value)
    list = value.kind_of?(Array) ? value : [value]
    value.each do |edge_group|
      box_check_box(edge_group)
    end if list.any?
  end

  def internal_publishing_location=(value)
    select_box('cdn_resource_internal_publishing_location_chzn', value) if value
  end

  def failover_internal_publishing_location=(value)
    select_box('cdn_resource_failover_internal_publishing_location_chzn', value) if value
  end

  def publishing_point=(value)
    select_box('cdn_resource_publishing_point_chzn', value) if value
  end

  def next_page
    self.next_button
    wait_for_ajax
  end

  def create_cdn_resource_button
    create_cdn_resource
    wait_for_ajax
  end

end