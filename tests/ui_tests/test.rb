require 'yaml'
require 'headless'
require 'rspec'
require 'ui_lib/login_page'
require 'ui_lib/add_cdn_resource_page'
require 'ui_lib/edit_cdn_resource_page'

describe 'CDN Resource Test Plan' do
  YAML::load_file('tests/ui_tests/cdn_tests.yml').each do |key, value|
    new_base = value['new']['base']
    new_advanced = value['new']['advanced']
    edit_base = value['edit']['base'] unless value['edit'].nil?
    edit_advanced = value['edit']['advanced'] unless value['edit'].nil?
    describe key do
      before :all do
        # @headless = Headless.new
        # @headless.start
        @browser = Selenium::WebDriver.for :ff
        @base_url = YAML::load_file('config/conf.yml')['url']
        @login_page = LoginPage.new(@browser, true)
        @home_page = @login_page.login
        @home_page.current_url.should eq("#{@base_url}/")
        @home_page.alert.should eq('Signed in successfully.')
        fail 'CDN is not enabled' unless @home_page.cdn_status?
      end
      it 'Create CDN Resource' do
        # TYPE SELECT TAB
        add_cdn_resource_page = AddCdnResourcePage.new(@browser, true)
        add_cdn_resource_page.cdn_resource_type = new_base['type'] unless new_base['type'].nil?
        add_cdn_resource_page.next_page

        # PROPERTIES TAB
        add_cdn_resource_page.cdn_hostname = new_base['hostname'] unless new_base['hostname'].nil?
        add_cdn_resource_page.enable_ssl= new_base['enable_ssl'] unless new_base['enable_ssl'].nil?
        add_cdn_resource_page.ssl_type = new_base['ssl_type'] unless new_base['ssl_type'].nil?
        add_cdn_resource_page.content_origin = new_base['content_origin'] unless new_base['content_origin'].nil?
        add_cdn_resource_page.storage_server_origin = new_base['storage_server_origin'] unless new_base['storage_server_origin'].nil?
        add_cdn_resource_page.ftp_password = new_base['ftp_password'] unless new_base['ftp_password'].nil?
        add_cdn_resource_page.ftp_password_confirmation = new_base['ftp_password'] unless new_base['ftp_password'].nil?
        add_cdn_resource_page.origin = new_base['origin'] unless new_base['origin'].nil?
        add_cdn_resource_page.origin1 = new_base['origin1'] unless new_base['origin1'].nil?
        add_cdn_resource_page.add_origin2 unless new_base['origin2'].nil?
        add_cdn_resource_page.origin2 = new_base['origin2'] unless new_base['origin2'].nil?
        add_cdn_resource_page.add_origin3 unless new_base['origin3'].nil?
        add_cdn_resource_page.origin3 = new_base['origin3'] unless new_base['origin3'].nil?
        add_cdn_resource_page.publishing_point = new_base['publishing_point'] unless new_base['publishing_point'].nil?
        add_cdn_resource_page.external_publishing_location = new_base['external_publishing_location'] unless new_base['external_publishing_location'].nil?
        add_cdn_resource_page.failover_external_publishing_location = new_base['external_publishing_location'] unless new_base['external_publishing_location'].nil?
        add_cdn_resource_page.next_page

        # EDGE LOCATION TAB

        add_cdn_resource_page.edge_groups = new_base['edge_groups'] unless new_base['edge_groups'].nil?
        add_cdn_resource_page.internal_publishing_location = new_base['internal_publishing_location'] unless new_base['internal_publishing_location'].nil?
        add_cdn_resource_page.failover_internal_publishing_location = new_base['failover_internal_publishing_location'] unless new_base['failover_internal_publishing_location'].nil?

        # ADVANCED SETTINGS
        unless new_advanced.nil?
          add_cdn_resource_page.next_page
        end
        # add_cdn_resource_page.create_cdn_resource
      end
      it 'Check creation' do

      end
      
      it 'Edit CDN Resources' do
        edit_cdn_resource_page = EditCdnResourcePage.new(@browser)
        edit_cdn_resource_page.advanced_settings = true
        edit_cdn_resource_page.access_policity = 'Allow by default'
        edit_cdn_resource_page.countries = 'Albania'
      end
      
      it 'Check After edit' do

      end

      it 'Delete CDN resource' do

      end



      after :all do
        @browser.close
        # @headless.destroy
      end
    end
  end
end
=begin
  describe  do
    before :all do
      # @headless = Headless.new
      # @headless.start
      @browser = Selenium::WebDriver.for :ff
      @base_url = YAML::load_file('config/conf.yml')['url']
      @login_page = LoginPage.new(@browser, true)
      @home_page = @login_page.login
      @home_page.current_url.should eq("#{@base_url}/")
      @home_page.alert.should eq('Signed in successfully.')
      fail 'CDN is not enabled' unless @home_page.cdn_status?
    end

    it 'Create CDN Resource' do
      add_cdn_resource_page = AddCdnResourcePage.new(@browser, true)
      add_cdn_resource_page.cdn_resource_type = 'http'
      add_cdn_resource_page.next_page
      add_cdn_resource_page.cdn_hostname = 'vovka.the.best'
      add_cdn_resource_page.content_origin = 'PULL'
      add_cdn_resource_page.origin1 = '10.10.10.10'
      add_cdn_resource_page.add_origin2
      add_cdn_resource_page.origin1 = 'vovka.the.best'
      add_cdn_resource_page.add_origin3
      add_cdn_resource_page.origin3 = '10.10.10.12'
      add_cdn_resource_page.remove_origin3
      add_cdn_resource_page.remove_origin2    #
      add_cdn_resource_page.add_origin2
      add_cdn_resource_page.origin2 = '10.10.10.11'
      add_cdn_resource_page.add_origin3
      add_cdn_resource_page.origin3 = '10.10.10.12'
      add_cdn_resource_page.next_page
      add_cdn_resource_page.edge_groups = 'iraEG1', 'iraEG3'
    end
    it 'Check creation' do

    end

    it 'Edit CDN Resources' do

    end

    it 'Check After edit' do

    end

    it 'Delete CDN resource' do

    end



    after :all do
      @browser.close
      # @headless.destroy
    end
  end
=end
