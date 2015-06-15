require 'yaml'
require 'headless'
require 'rspec'
require 'ui_lib/login_page'
require 'ui_lib/add_cdn_resource_page'

describe 'basic test' do
  before :all do
    # @headless = Headless.new
    # @headless.start
    @browser = Selenium::WebDriver.for :ff
    @base_url = YAML::load_file('config/conf.yml')['url']
    @login_page = LoginPage.new(@browser, true)
    @home_page = @login_page.login
    @home_page.current_url.should eq("#{@base_url}/")
    @home_page.alert.should eq('Signed in successfully.')
  end


  it 'Create CDN Resource' do
    @add_cdn_resource_page = AddCdnResourcePage.new(@browser, true)

    @add_cdn_resource_page.cdn_resource_type = 'http'
    @add_cdn_resource_page.next_page

     @add_cdn_resource_page.cdn_hostname = 'vovka.the.best'
     @add_cdn_resource_page.content_origin = 'PULL'
     @add_cdn_resource_page.origin1 = '10.10.10.10'
     @add_cdn_resource_page.add_origin2
     @add_cdn_resource_page.origin1 = 'vovka.the.best'
     @add_cdn_resource_page.add_origin3
     @add_cdn_resource_page.origin3 = '10.10.10.12'
     @add_cdn_resource_page.remove_origin3
     @add_cdn_resource_page.remove_origin2    #
     @add_cdn_resource_page.add_origin2
     @add_cdn_resource_page.origin2 = '10.10.10.11'
     @add_cdn_resource_page.add_origin3
     @add_cdn_resource_page.origin3 = '10.10.10.12'
     @add_cdn_resource_page.next_page
     @add_cdn_resource_page.edge_groups = 'iraEG1', 'iraEG3'


  end
  it 'Edit CDN Resources' do
    @add_cdn_resource_page = AddCdnResourcePage.new(@browser, true)
  end



  after :all do
    @browser.close
    # @headless.destroy
  end

end