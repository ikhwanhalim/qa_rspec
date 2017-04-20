class BillingPlanResource

  attr_reader :interface, :billing_plan, :id

  def initialize(billing_plan)
    @interface    = billing_plan.interface
    @billing_plan = billing_plan
  end

  def attrs_update(attrs=nil)
    attrs ||= interface.get(route_limit)
    attrs.values.first.each { |k,v| instance_variable_set("@#{k}", v) }

    self
  end

  def add_limit_eg(eg_id, **params)
    data = create_params_limit_eg(eg_id).merge(**params)
    json_response = interface.post("#{route_limits}", resource: data)
    attrs_update json_response
  end

  def create_params_limit_eg(eg_id)
    {
       resource_class: "Resource::EdgeGroup",
       billing_plan_id: billing_plan.id.to_s,
       target_id: eg_id.to_s,
       target_type: "EdgeGroup",
       price: "6"
    }
  end

  #TODO think about rewriting the next 3 methods
  def add_to_current_bp_limit_eg(billing_plan_id, eg_id, **params)
    data = create_params_limit_eg_to_current_bp(billing_plan_id, eg_id).merge(params)
    json_response = interface.post("#{route_to_current_billing_plan}", resource: data)
    attrs_update json_response
  end

  def create_params_limit_eg_to_current_bp(billing_plan_id, eg_id)
    {
        resource_class: "Resource::EdgeGroup",
        billing_plan_id: billing_plan_id.to_s,
        target_id: eg_id.to_s,
        target_type: "EdgeGroup",
        price: "6"
    }
  end

  def route_to_current_billing_plan
    "/billing/user/plans/#{billing_plan.get_current_bp_id}/resources"
  end

  def get
    json_response  = interface.get(route_detail_limit)
    attrs_update json_response
  end

  def delete
    interface.delete route_detail_limit
  end

  def route_billing_plan
    "/billing/user/plans/#{billing_plan.id}"
  end

  def route_limits
    "#{route_billing_plan}/resources"
  end

  def route_limit
   "#{route_limits}/#{id}"
  end

  def route_detail_limit
    "/billing/user/resources/#{id}"
  end
end
