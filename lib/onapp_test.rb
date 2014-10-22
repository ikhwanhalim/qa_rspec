require "onapp_control_panel"
require "onapp_database"
require "managers"
require "helpers/template_manager"

class OnappTest
  include TemplateManager

	def initialize
	  $cp = OnappControlPanel.new
	  $db = OnappDataBase.new
	  $roles = RoleManager.new
	  $users = UserManager.new
	  $billing_plans = BillingManager.new
	end
end
