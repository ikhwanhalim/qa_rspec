# Test for checking Billing Plan functionality.

require './lib/onapp_billing'
require './lib/onapp_user'
require './lib/onapp_role'

describe "Checking Billing Plan functionality" do
  before(:all) do
    @bp = OnappBilling.new
    @user = OnappUser.new
    @role = OnappRole.new
    @role.create_user_role
    bp_data = {'label' => 'Test User BP',
            'monthly_price' => '100.0',
            'currency_code' => 'USD'}
    @bp.create_billing_plan(bp_data)
  end

  after(:all) do
    @user.delete_user({:force => true})
    @bp.delete_billing_plan
    @role.delete_role
  end

  it "Create User with empty parameters" do
    data = {}
    response = @user.create_user(data)
    expect(response['login']).to include("can't be blank") and
        expect(response['email']).to include("can't be blank") and
        expect(response['password'].first).to include("is too short")
  end

  it "Create User with required parameters" do
    data = {:login => 'autotestuser',
            :email => 'autotest@user.test',
            :password => 'qwaszxsdomino!Q2'
    }
    response = @user.create_user(data)
    expect(response['login']).to eq(data[:login]) and
        expect(response['email']).to eq(data[:email])
  end

  it "Edit User, set first_name" do
    data = {:first_name => 'AutoTest'}
    @user.edit_user(data)
    response = @user.get_user_by_id(@user.user_id)
    expect(response['first_name']).to eq(data[:first_name])
  end

  it "Edit User, set last_name" do
    data = {:last_name => 'User'}
    @user.edit_user(data)
    response = @user.get_user_by_id(@user.user_id)
    expect(response['last_name']).to eq(data[:last_name])
  end

  it "Edit User, set time_zone" do
    data = {:time_zone => 'Kyiv'}
    @user.edit_user(data)
    response = @user.get_user_by_id(@user.user_id)
    expect(response['time_zone']).to eq(data[:time_zone])
  end

  it "Edit User, set role_ids" do
    data = {:role_ids => [1]}
    @user.edit_user(data)
    response = @user.get_user_by_id(@user.user_id)
    expect(response['roles'].first['role']['id']).to eq(data[:role_ids].first)
  end

  it "Edit User, set user_password" do
    data = {:user_password => 'qwaszxsdomino!Q2'}
    @user.edit_user(data)
    response = @user.get_user_by_id(@user.user_id)
    @new_user = OnappUser.new(user= response['login'], pass=data[:user_password])
    response = @new_user.get_user_by_id(@user.user_id)
    expect(response['id']).to eq(@user.user_id)
  end

  it "Edit User, set BillingPlan" do
    data = {:billing_plan_id => @bp.bp_id}
    @user.edit_user(data)
    response = @user.get_user_by_id(@user.user_id)
    expect(response['billing_plan_id']).to eq(@bp.bp_id)
  end

  it "Access to settings should be blocked for user" do
    @role.remove_permission("settings.read")
    data = {:role_ids => [@role.role_id]}
    @user.edit_user(data)
    @user.login_as_user
    @user.get("#{@user.url}/settings.json")
    expect(@user.get("#{@user.url}/settings.json")['error']).to eq("You do not have permissions for this action")
    @user.login_as_user(1)
  end

end
