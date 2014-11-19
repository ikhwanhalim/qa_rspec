# Test for checking Billing Plan functionality.

require './lib/onapp_role'

describe "Checking Billing Plan functionality" do
  before(:all) do
    @role = OnappRole.new
  end

  after(:all) do
  end

  it "Create Role with users permissions" do
    @role.create_user_role
  end

  it "Delete Role with users permissions" do
    @role.delete_role(@role.role_id)
  end

  it "Create Role with admin permissions" do
    @role.create_admin_role
  end

  it "Delete Role with admin permissions" do
    @role.delete_role(@role.role_id)
  end
end
