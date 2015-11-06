require 'yaml'
require 'headless'
require 'rspec'
require 'ui_lib/login_page'
require 'ui_lib/add_cdn_resource_page'
require 'ui_lib/edit_cdn_resource_page'
require 'ui_lib/detail_cdn_resource_page'
require 'ui_lib/cdn_resources_page'

describe 'CDN Resource Test Plan' do
  YAML::load_file('spec/ui_tests/cdn_tests.yml').each do |key, value|
    new_base = value['new']['base']
    new_advanced = value['new']['advanced']
    edit_base = value['edit']['base'] unless value['edit'].nil?
    edit_advanced = value['edit']['advanced'] unless value['edit'].nil?
    describe key do
      include DetailCdnResourcePage
      before :all do
        # @headless = Headless.new
        # @headless.start
        @browser = Selenium::WebDriver.for :ff
        @base_url = YAML::load_file('config/conf.yml')['url']
        @login_page = LoginPage.new(@browser, true)
        @home_page = @login_page.login
        expect(@home_page.current_url).to eq("#{@base_url}/")
        expect(@home_page.alert).to eq('Signed in successfully.')
        fail 'CDN is not enabled' unless @home_page.cdn_status?
      end

      after :all do
        @browser.close
        # @headless.destroy
      end

      it 'Create CDN Resource' do
        # TYPE SELECT TAB
        add_cdn_resource_page = AddCdnResourcePage.new(@browser, true)
        add_cdn_resource_page.cdn_resource_type = new_base['type'] unless new_base['type'].nil?
        add_cdn_resource_page.next_page

        # PROPERTIES TAB
        add_cdn_resource_page.cdn_hostname = new_base['hostname']
        add_cdn_resource_page.enable_ssl= new_base['enable_ssl']
        add_cdn_resource_page.ssl_type = new_base['ssl_type']
        add_cdn_resource_page.content_origin = new_base['content_origin']
        add_cdn_resource_page.storage_server_origin = new_base['storage_server_origin']
        add_cdn_resource_page.ftp_password = new_base['ftp_password']
        add_cdn_resource_page.ftp_password_confirmation = new_base['ftp_password']
        add_cdn_resource_page.resource_origin = new_base['origin']
        add_cdn_resource_page.publishing_point = new_base['publishing_point']
        add_cdn_resource_page.external_publishing_location = new_base['external_publishing_location']
        add_cdn_resource_page.failover_external_publishing_location = new_base['external_publishing_location']
        add_cdn_resource_page.next_page

        # EDGE LOCATION TAB

        add_cdn_resource_page.edge_groups = new_base['edge_groups']
        add_cdn_resource_page.internal_publishing_location = new_base['internal_publishing_location']
        add_cdn_resource_page.failover_internal_publishing_location = new_base['failover_internal_publishing_location']

        # ADVANCED SETTINGS
        unless new_advanced.nil?
          add_cdn_resource_page.next_page
          add_cdn_resource_page.origin_policy= new_advanced['origin_policy']
          add_cdn_resource_page.country_access_policy= new_advanced['country_access_policy']
          add_cdn_resource_page.except_for_countries=new_advanced['except_for_countries']
          add_cdn_resource_page.hotlink_policy= new_advanced['hotlink_policy']
          add_cdn_resource_page.except_for_domains= new_advanced['except_for_domains']
          add_cdn_resource_page.ip_access_policy= new_advanced['ip_access_policy']
          add_cdn_resource_page.except_for_ip= new_advanced['except_for_ip']
          add_cdn_resource_page.secondary_cdn_hostnames= new_advanced['secondary_cdn_hostnames']
          add_cdn_resource_page.enable_url_signing= new_advanced['enable_url_signing']
          add_cdn_resource_page.url_signing_key= new_advanced['url_signing']
          add_cdn_resource_page.cache_expiry= new_advanced['cache_expiry']
          add_cdn_resource_page.enable_password= new_advanced['enable_password']
          add_cdn_resource_page.unauthorized_html= new_advanced['unauthorized_html']
          add_cdn_resource_page.credentials= new_advanced['credentials']
          add_cdn_resource_page.enable_mp4_pseudo_streaming= new_advanced['enable_mp4_pseudo_streaming']
          add_cdn_resource_page.enable_flv_pseudo_streaming= new_advanced['enable_flv_pseudo_streaming']
          add_cdn_resource_page.ignore_set_cookie= new_advanced['ignore_set_cookie']
          add_cdn_resource_page.limit_rate= new_advanced['limit_rate']
          add_cdn_resource_page.limit_rate_after=new_advanced['limit_rate_after']
          add_cdn_resource_page.proxy_read_time_out= new_advanced['proxy_read_time_out']
          add_cdn_resource_page.proxy_connect_time_out= new_advanced['proxy_connect_time_out']
          add_cdn_resource_page.proxy_cache_key= new_advanced['proxy_cache_key']
          add_cdn_resource_page.block_search_engine_crawlers= new_advanced['block_search_engine_crawlers']
        end

         add_cdn_resource_page.create_cdn_resource_button
      end

      it 'Check creation' do
          detail_cdn_resource_page = DetailCdnResourcePage::Basic.new(@browser)
          detail_cdn_resource_page.wait_for_activation
          detail_cdn_resource_page.check_data_on_page(new_base, new_advanced)
          detail_cdn_resource_page.press_advanced_details
          detail_cdn_resource_page = DetailCdnResourcePage::Advanced.new(@browser)
          detail_cdn_resource_page.check_data_ona_page(new_base, new_advanced)
      end
      
      it 'Edit CDN Resources' do
        skip unless value['edit']
        edit_cdn_resource_page = EditCdnResourcePage.new(@browser)
        edit_cdn_resource_page.advanced_settings = true
        edit_cdn_resource_page.access_policity = 'Allow by default'
        edit_cdn_resource_page.countries = 'Albania'
      end
      
      it 'Check After edit' do
        skip unless value['edit']
      end

      it 'Delete CDN resource' do
        # cdn_resources_page = CdnResourcesPage.new(@browser)
        # cdn_resources_page.delete
      end
    end
  end
end
