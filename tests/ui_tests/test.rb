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
  end

  it 'Login to OnApp CP' do
    @login_page = LoginPage.new(@browser, true)
    @home_page = @login_page.login
    @home_page.current_url.should eq("#{@base_url}/")
    @home_page.alert.should eq('Signed in successfully.')
  end
  it 'Create CDN Resource' do
    @add_cdn_resource_page = AddCdnResourcePage.new(@browser, true)
    @add_cdn_resource_page.unlock_drop_down # USED FOR CORRECT DROPDOWNS. Affect UI

    @add_cdn_resource_page.check_http
    @add_cdn_resource_page.http_checked?.should be_truthy
    @add_cdn_resource_page.next_page

    @add_cdn_resource_page.cdn_hostname = 'vovka.the.best'

    @add_cdn_resource_page.check_enable_ssl
    sleep 5
    @add_cdn_resource_page.enable_ssl_checked?.should be_truthy
    @add_cdn_resource_page.check_custom_sni_ssl
    @add_cdn_resource_page.custom_snk_ssl_list = 'None Specified'

    @add_cdn_resource_page.content_origin = 'PUSH'

    @add_cdn_resource_page.storage_server_location = 'DZ, Adrar'

    @add_cdn_resource_page.ftp_password = 'hello world'
    @add_cdn_resource_page.ftp_password_confirmation = 'hello world'

    @add_cdn_resource_page.next_page

    sleep 5



  end


  after :all do
    @browser.close
    # @headless.destroy
  end

end