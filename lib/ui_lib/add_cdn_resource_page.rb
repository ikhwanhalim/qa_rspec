require 'yaml'
require 'page-object'
require 'selenium-webdriver'

class AddCdnResourcePage
  include PageObject
  PageObject.javascript_framework = :jquery


  page_url "#{YAML::load_file('config/conf.yml')['url']}/cdn_resources/new"

  checkbox(:http, :id => 'cdn_resource_resource_type_http_pull')
  checkbox(:vod, :id => 'cdn_resource_resource_type_stream_vod_pull')
  checkbox(:live_streaming, :id => 'cdn_resource_resource_type_stream_vod_pull')

  text_field(:cdn_hostname, :id => 'cdn_resource_cdn_hostname')

  # checkbox(:enable_ssl, :id => 'enable_ssl_checkbox')
  checkbox(:enable_ssl, :name => 'cdn_resource[enable_ssl]')
  checkbox(:shared_ssl, :id => 'cdn_resource_ssl_type_ssl_on')
  checkbox(:custom_sni_ssl, :id => 'cdn_resource_ssl_type_ssl')
  select_list(:custom_sni_ssl_list, :id => 'cdn_resource_cdn_ssl_certificate_id')

  select_list(:content_origin, :id => 'cdn_resource_content_origin')

  select_list(:storage_server_location, :id => 'cdn_resource_storage_server_location')

  text_field(:ftp_password, :id => 'cdn_resource_ftp_password')
  text_field(:ftp_password_confirmation, :id => 'cdn_resource_ftp_password_confirmation')

  button(:next_button, :xpath => "//button[@class = 'round-button next']")
  @page = 1
  def unlock_drop_down
    browser.execute_script("document.getElementById('cdn_resource_cdn_ssl_certificate_id').style = 'display: block';")
    browser.execute_script("document.getElementById('cdn_resource_content_origin').style = 'display: block';")
    browser.execute_script("document.getElementById('cdn_resource_storage_server_location').style = 'display: block';")
    browser.execute_script("document.getElementsByName('cdn_resource[enable_ssl]')[0].type = '';")
    wait_until { custom_sni_ssl_list?}
    wait_until { content_origin?}
    wait_until { storage_server_location?}
  end

  def next_page
    self.next_button
    wait_for_ajax
  end

end