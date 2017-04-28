class BillingPlanActions
  include ApiClient, Log

  attr_reader  :billing_plan, :currency

  def precondition
    @billing_plan = BillingPlan.new(self)
    @currency = Currency.new(self)

    self
  end
end
