require "helpers/curl"
require "helpers/parser"

class OnappBilling
    include Curl
    include Parser

    attr_reader :id, :label, :currency_code, :allows_mak, :allows_kms, :allows_own, :monthly_price

    def initialize

    end
    def add_default
        data = from_api(get("/billing_plans/#{$users.admin.billing_plan_id}"))
        fill_data(data)
        return self
    end







    private
    def fill_data(data)
        @id = data[:id]
        @label = data[:label]
        @currency_code = data[:currency_code]
        @allows_mak = data[:allows_mak]
        @allows_kms = data[:allows_kms]
        @allows_own = data[:allows_own]
        @monthly_price = data[:monthly_price]
    end





end