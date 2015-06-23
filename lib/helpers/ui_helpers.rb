require 'page-object'
require 'selenium-webdriver'


module UiHelpers
  def select_box(id, value)
    browser.find_elements(:xpath => "//div[@id = '#{id}']/a/div").first.click()
    wait_for_ajax
    browser.find_elements(:xpath => "//div[@id = '#{id}']//input").first.send_keys(value)
    wait_for_ajax
    browser.find_elements(:xpath => "//div[@id = '#{id}']//li/em[contains(text(),'#{value}')]").first.click()
    wait_for_ajax
  end

  def slide_check_box(id, value)
    if !value && browser.find_elements(:xpath => "//input[@id = '#{id}']/../div[@class='switch_handle']").any?
      browser.find_elements(:xpath => "//input[@id = '#{id}']/..").first.click()
    elsif value && !browser.find_elements(:xpath => "//input[@id = '#{id}']/../div[@class='switch_handle']").any?
      browser.find_elements(:xpath => "//input[@id = '#{id}']/..").first.click()
    end
    wait_for_ajax
  end

  def box_check_box(value)
    browser.find_elements(:xpath => "//h3[@title='#{value}']/..//input").first.click()
    wait_for_ajax
  end

  def multi_select_box(id, value)
    list = value.kind_of?(Array) ? value : [value]
    list.each do |el|
      browser.find_elements(:xpath => "//div[@id = '#{id}']/ul").first.click
      wait_for_ajax
      browser.find_elements(:xpath => "//div[@id = '#{id}']//input").first.send_keys(el)
      wait_for_ajax
      browser.find_elements(:xpath => "//div[@id = '#{id}']//*[contains(text(),'#{el}')]").first.click()
      wait_for_ajax
    end
  end

  def drop_down_actions(action)
    action_path = "//*[contains(@href,'#{@resource_path}')][contains(text(),'#{action}')]"
    action_button_path = action_path + "/ancestor::*[@class='actions']/a"
    browser.find_elements(:xpath => action_button_path).first.click
    wait_for_ajax
    browser.find_elements(:xpath => action_path).first.click
    browser.switch_to.alert.accept if action == 'Delete'
  end
end
