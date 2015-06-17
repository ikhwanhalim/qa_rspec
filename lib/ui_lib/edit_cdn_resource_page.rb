require 'yaml'
require 'page-object'
require 'selenium-webdriver'
require 'helpers/ui_helpers'

class EditCdnResourcePage
  include PageObject
  include UiHelpers
  attr_accessor :countries, :advanced_settings, :access_policy

  PageObject.javascript_framework = :jquery

  def advanced_settings=(value)
    slide_check_box('advanced_checkbox', value)
  end

  def access_policy=(value)
    select_box('cdn_resource_country_access_policy_chzn', value)
  end

  def countries=(value)
    multi_select_box('cdn_resource_countries_chzn', value)
  end

  def goto_edit
    self.class.page_url(browser.current_url + '/edit')
    goto
  end
end