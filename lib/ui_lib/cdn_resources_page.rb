require 'yaml'
require 'page-object'
require 'selenium-webdriver'
require 'helpers/ui_helpers'

class CdnResourcesPage
  include PageObject
  include UiHelpers

  PageObject.javascript_framework = :jquery
  page_url "#{YAML::load_file('config/conf.yml')['url']}/cdn_resources/per_page/all"

  def initialize(browser, visit=true)
    @resource_path = browser.current_url.match(/http(s)?:\/\/\S+(\/cdn_resources\/\d+)/).to_a[2]
    super
  end

  def delete
    drop_down_actions('Delete')
  end

  def edit
    drop_down_actions('Edit')
  end
end