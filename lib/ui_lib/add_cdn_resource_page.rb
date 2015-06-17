require 'yaml'
require 'page-object'
require 'selenium-webdriver'
require 'helpers/ui_helpers'

class AddCdnResourcePage
  include PageObject
  include UiHelpers

  PageObject.javascript_framework = :jquery


  page_url "#{YAML::load_file('config/conf.yml')['url']}/cdn_resources/new"

  checkbox(:http, :id => 'cdn_resource_resource_type_http_pull')
  checkbox(:vod, :id => 'cdn_resource_resource_type_stream_vod_pull')
  checkbox(:live_streaming, :id => 'cdn_resource_resource_type_stream_live')

  text_field(:cdn_hostname, :id => 'cdn_resource_cdn_hostname')
  text_field(:ftp_password, :id => 'cdn_resource_ftp_password')
  text_field(:ftp_password_confirmation, :id => 'cdn_resource_ftp_password_confirmation')

  text_field(:origin, :id => 'cdn_resource_origin')

  text_field(:origin1, :xpath => '//ul[@id = "origins-multiply-field"]/li[1]//input[@name="cdn_resource[origins][]"]')
  text_field(:origin2, :xpath => '//ul[@id = "origins-multiply-field"]/li[2]//input[@name="cdn_resource[origins][]"]')
  text_field(:origin3, :xpath => '//ul[@id = "origins-multiply-field"]/li[3]//input[@name="cdn_resource[origins][]"]')
  button(:remove_origin1, :xpath => '//ul[@id = "origins-multiply-field"]/li[1]//input[@name="cdn_resource[origins][]"]/../a')
  button(:remove_origin2, :xpath => '//ul[@id = "origins-multiply-field"]/li[2]//input[@name="cdn_resource[origins][]"]/../a')
  button(:remove_origin3, :xpath => '//ul[@id = "origins-multiply-field"]/li[3]//input[@name="cdn_resource[origins][]"]/../a')
  button(:add_origin2, :xpath => '//ul[@id = "origins-multiply-field"]/li[1]//span[@class="icon add"]')
  button(:add_origin3, :xpath => '//ul[@id = "origins-multiply-field"]/li[2]//span[@class="icon add"]')

  text_field(:external_publishing_location, :id => 'cdn_resource_external_publishing_location')
  text_field(:failover_external_publishing_location, :id => 'cdn_resource_failover_external_publishing_location')
  checkbox(:shared_ssl, :id => 'cdn_resource_ssl_type_ssl_on')
  checkbox(:custom_sni_ssl, :id => 'cdn_resource_ssl_type_ssl')

  button(:next_button, :xpath => "//button[@class = 'round-button next']")
  button(:create_cdn_resource, :xpath => "//button[@type = 'submit']")

  define_method ("cdn_resource_type=") do |value|
    case value
      when 'http'
        check_http
      when 'vod'
        check_vod
      when 'live_streaming'
        check_live_streaming
      else
        raise "Unknown CDN resource type: #{value}"
    end
  end

  define_method ("enable_ssl=") do |value|
    slide_check_box('enable_ssl_checkbox', value)
  end
  define_method ("ssl_type=") do |value|
    case value
      when 'shared'
        check_shared_ssl
      when 'custom'
        check_custom_sni_ssl
      else
        raise "Unknown SSL type: #{value}"
    end
  end
  define_method ("custom_sni_ssl=") do |value|
    select_box('cdn_resource_content_origin_chzn', value)
  end

  define_method ("content_origin=") do |value|
    select_box('cdn_resource_content_origin_chzn', value)
  end
  define_method ("storage_server_origin=") do |value|
    select_box('cdn_resource_storage_server_location_chzn', value)
  end
  define_method ("edge_groups=") do |value|
    value.each do |edge_group|
      box_check_box(edge_group)
    end
  end
  define_method ("internal_publishing_location=") do |value|
    select_box('cdn_resource_internal_publishing_location_chzn', value)
  end
  define_method ("failover_internal_publishing_location=") do |value|
    select_box('cdn_resource_failover_internal_publishing_location_chzn', value)
  end
  define_method ("publishing_point=") do |value|
    select_box('cdn_resource_publishing_point_chzn', value)
  end




  def next_page
    self.next_button
    wait_for_ajax
  end
  def create_cdn_resource_button
    self.create_cdn_resource
    wait_for_ajax
    # return CdnResourceDetailsPage.new(browser, false)
  end

end