# Test for checking Billing Plan functionality.

require './lib/onapp_billing'

describe "Checking Billing Plan functionality" do
  before(:all) do
    @bp = OnappBilling.new
  end

  after(:all) do
  end

  it "Create Billin Plan with empty 'Label'" do
    data = {'label' => ''}
    response = @bp.create_billing_plan(data)
    expect(response['label'].first).to eq("can't be blank")
  end
#
  it "Create Billing Plan with negative price value" do
    data = {'monthly_price' => '-100.0'}
    response = @bp.create_billing_plan(data)
    expect(response['monthly_price'].first).to eq("must be greater than or equal to 0")
  end
#
  it "Create Billin Plan with unexisted currency" do
    data = {'label' => 'Test BP', 'currency_code' => 'AAA'}
    response = @bp.create_billing_plan(data)
    expect(response['currency_code'].first).to eq("must be included in list of currencies")
  end
#
  it "Create Billing Plan with correct values" do
    data = {'label' => 'Test zaza BP',
            'monthly_price' => '100.0',
            'currency_code' => 'USD'}
    response = @bp.create_billing_plan(data)
    expect(response['label']).to eq(data['label']) and
    expect(response['monthly_price']).to eq(data['monthly_price']) and
    expect(response['currency_code']).to eq(data['currency_code'])
   end
#
  it "Edit Billin Plan with empty 'Label'" do
    data = {'label' => ''}
    response = @bp.edit_billing_plan(data)
    expect(response['label'].first).to eq("can't be blank")
  end
#
  it "Edit Billing Plan with negative price value" do
    data = {'monthly_price' => '-100.0'}
    response = @bp.edit_billing_plan(data)
    expect(response['monthly_price'].first).to eq("must be greater than or equal to 0")
  end
#
  it "Edit Billin Plan with unexisted currency" do
    data = {'currency_code' => 'AAA'}
    response = @bp.edit_billing_plan(data)
    expect(response['currency_code'].first).to eq("must be included in list of currencies")
  end
#
  it "Edit Billing Plan with correct values" do
    data = {'label' => 'Test zaza BP changed',
            'monthly_price' => '101.0',
            'currency_code' => 'EUR'}

    @bp.edit_billing_plan(data)
    response = @bp.get_billing_plan(@bp.bp_id)
    expect(response['label']).to eq(data['label']) and
    expect(response['monthly_price']).to eq(data['monthly_price']) and
    expect(response['currency_code']).to eq(data['currency_code'])
  end
#
  it "Delete Billing Plan" do
    @bp.delete_billing_plan
    response = @bp.get_billing_plan(@bp.bp_id)
    expect(response.first).to eq('BillingPlan not found')
  end
end
