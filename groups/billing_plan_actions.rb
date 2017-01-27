class BillingPlanActions
  include ApiClient, Log

  attr_reader :billing_plan

  def precondition
    @billing_plan = BillingPlan.new(self).create_billing_plan

    self
  end
end
