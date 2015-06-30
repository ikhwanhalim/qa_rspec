require 'yaml'
require 'page-object'
require 'selenium-webdriver'
require 'ui_lib/dashboard_page'




class LoginPage
  include PageObject
  data = YAML::load_file('config/conf.yml')
  page_url "#{data['url']}/users/sign_in"

  DEFAULT_LOGIN = {
      'user_login' => "#{data['user']}",
      'user_password' => "#{data['pass']}"
  }

  text_field(:user_login, :id => 'user_login')
  text_field(:user_password, :id => 'user_password')
  button(:submit, :name => 'commit')

  # Exception
  span(:alert, :xpath => '//span/span')

  def login(data={})
    populate_page_with DEFAULT_LOGIN.merge(data)
    submit
    DashboardPage.new(browser, false)
  end
end
