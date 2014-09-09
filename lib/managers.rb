require "onapp_user"
require "onapp_billing"


class UserManager
    def initialize()
        @users = Array.new
        @users << OnappUser.new().add_admin
    end
    def admin
        return @users.first
    end
    def user(login)
        @users.each do |user|
            return user if user.login == login
        end
        raise ("Unable to locate user with login = #{login} associated to test")
    end
end

class BillingManager
    def initialize()
        @billing_plans = Array.new
        @billing_plans << OnappBilling.new().add_default
    end
    def default
        return @billing_plans.first
    end
    def billing_plan(id)
        @billing_plans.each do |billing_plan|
            return billing_plan if billing_plan.id == id
        end
        raise ("Unable to locate BP with id = #{id} associated to test")
    end
end

class RoleManager
    def initialize()
        @roles = Array.new
    end
    def role(id)
        @roles.each do |role|
            return role if role.id == id
        end
        raise ("Unable to locate ROLE with id = #{id} associated to test")
    end
end