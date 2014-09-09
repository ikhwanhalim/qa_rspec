require "helpers/curl"
require "helpers/parser"


class OnappUser
    include Curl
    include Parser

    attr_reader :id, :first_name, :last_name, :email, :locale, :login, :password, :time_zone, :billing_plan_id

    def initialize

    end
    def add_admin
        @id = $db.select_user($cp.admin.split(":").first)
        @login = $cp.admin.split(":").first
        @password = $cp.admin.split(":").last
        data = from_api(get("/users/#{id}"))
        fill_data(data)
        set_as_current
        return self
    end
    def create(data)

    end

    def set_as_current
        $current_user = "#{login}:#{password}"
    end

    def billing_plan
        $billing_plans.billing_plan(billing_plan_id)
    end



    private
    def fill_data(data)
        @login = data[:login]
        @id = data[:id]
        @first_name = data[:first_name]
        @last_name = data[:last_name]
        @email = data[:email]
        @locale = data[:locale]
        @time_zone = data[:time_zone]
        @billing_plan_id = data[:billing_plan_id]
    end


end