# Test for checking Billing Plan functionality.

require './lib/onapp_billing'
require './lib/onapp_user'

describe "Checking Billing Plan functionality" do
  before(:all) do
    @bp = OnappBilling.new
    @user = OnappUser.new
    data = {'label' => 'Test User BP',
            'monthly_price' => '100.0',
            'currency_code' => 'USD'}
    @bp.create_billing_plan(data)
  end

  after(:all) do
    @bp.delete_billing_plan(@bp.bp_id)
  end

  it "Create User with empty parameters" do
    data = {}
    response = @user.create_user(data)
    expect(response['errors']['login']).to include("can't be blank") and
        expect(response['errors']['email']).to include("can't be blank") and
        expect(response['errors']['password']).to include("should include letters and digits")
  end

  it "Create User with required parameters" do
    data = {:login => 'autotestuser',
            :email => 'autotest@user.test',
            :password => 'qwaszxsdomino!Q2'
    }
    response = @user.create_user(data)
    expect(response['user']['login']).to eq(data[:login])
  end

  it "Edit User, set first_name" do
    data = {:first_name => 'AutoTest'
    }
    @user.edit_user(@user.user_id, data)
    response = @user.get_user_by_id(@user.user_id)
    expect(response['user']['first_name']).to eq(data[:first_name])
  end

  it "Edit User, set last_name" do
    data = {:last_name => 'User'
    }
    @user.edit_user(@user.user_id, data)
    response = @user.get_user_by_id(@user.user_id)
    expect(response['user']['last_name']).to eq(data[:last_name])
  end

  it "Edit User, set time_zone" do
    data = {:time_zone => 'Kyiv'
    }
    @user.edit_user(@user.user_id, data)
    response = @user.get_user_by_id(@user.user_id)
    expect(response['user']['time_zone']).to eq(data[:time_zone])
  end

  it "Edit User, set role_ids" do
    data = {:role_ids => [1]
    }
    @user.edit_user(@user.user_id, data)
    response = @user.get_user_by_id(@user.user_id)
    expect(response['user']['roles'].first['role']['id']).to eq(data[:role_ids].first)
  end

  it "Edit User, set user_password" do
    data = {:user_password => 'qwaszxsdomino!Q2'
    }
    @user.edit_user(@user.user_id, data)
    response = @user.get_user_by_id(@user.user_id)
    @new_user = OnappUser.new(user= response['user']['login'], pass=data[:user_password])
    response = @new_user.get_user_by_id(@user.user_id)
    expect(response['user']['id']).to eq(@user.user_id)
  end
  #
  it "Delete User" do
    data = {:force => true}
    @user.delete_user(@user.user_id, data)
    sleep(2)
    response = @user.get_user_by_id(@user.user_id)
    expect(response['errors'].first).to eq('User not found')
  end
end
