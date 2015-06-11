require 'yaml'
require 'page-object'
require 'selenium-webdriver'

class DashboardPage
  include PageObject
  page_url YAML::load_file('config/conf.yml')['url']


  span(:alert, :xpath => '//span/span')

end