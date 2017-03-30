class BillingPlan

  attr_reader :interface, :resources, :id

  def initialize(interface)
    @resources = []
    @interface = interface
  end

  def generate_name(chars_count)
    rand(36**chars_count).to_s(36)
  end

  def attrs_update(attrs=nil)
    attrs ||= interface.get(route_billing_plan)
    attrs.values.first.each { |k,v| instance_variable_set("@#{k}", v) }

    self
  end

  def create_billing_plan(**params)
    data = create_params.merge(**params)
    json_response = interface.post(route_billing_plans, user_plan: data)
    attrs_update json_response
  end

  def create_params
    {
       label: "ad-qa-ant-#{generate_name(4)}",
       currency_code: "USD",
       monthly_price: "24",
       allows_kms: "false",
       allows_mak:"true",
       allows_own: "false"
    }
  end

  def create_limit_eg(eg_id, **params)
    resources = BillingPlanResource.new(self).add_limit_eg(eg_id, params)
    @resources << resources
    resources
  end

  #TODO think about rewriting the next two methods
  def create_limit_eg_for_current_bp(billing_plan_id, eg_id, **params)
    resources = BillingPlanResource.new(self).add_to_current_bp_limit_eg(billing_plan_id, eg_id, params)
    @resources << resources
    resources
  end

  def get_current_bp_id
    interface.get('/profile').user.billing_plan_id
  end

  def copy_billing_plan
    interface.post route_copy_billing_plan
  end

  def remove_billing_plan
    interface.delete route_billing_plan
  end

  def route_billing_plans
    "/billing/user/plans"
  end

  def route_copy_billing_plan
    "#{route_billing_plans}/1/create_copy"
  end

  def route_billing_plan
    "#{route_billing_plans}/#{id}"
  end

  def route_base_resources
    "#{route_billing_plan}/resources"
  end
end