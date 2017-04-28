class User
  include Transaction
  attr_reader :interface, :id, :billing_plan_id, :ssh_key, :login, :email, :first_name, :last_name, :password,
              :user_group_id, :role_ids, :time_zone, :locale

  def initialize(interface)
    @interface = interface
  end

  def create(**params)
    response = interface.post('/users', { user: build_params.merge(params) })
    response_handler response
    self
  end

  def build_params
    {
        login: "autotest_#{SecureRandom.hex(4)}",
        first_name: 'Auto',
        last_name: 'Test',
        billing_plan_id:' 1',#@billing_plan_id,
        email: Faker::Internet.email('autotest'),
        password: interface.settings.generate_password,
        role_ids: ['1']
    }
  end

  def remove(erase: true)
    interface.delete(route, {force: erase})
    wait_for_destroy_user
  end

  def find(user_id)
    response_handler interface.get("/users/#{user_id}")
  end

  def add_ssh_key
    @ssh_key = SshKey.new(self)
    response = @ssh_key.add_ssh_key
    return if response['errors']
  end

  def remove_ssh_key
    @ssh_key.remove_ssh_key
  end

  def route
    "/users/#{id}"
  end

  def wait_for_destroy_user
    wait_for_transaction(id, 'User', 'destroy_user')
  end

  def api_response_code
    interface.conn.page.code
  end

  private

  def response_handler(response)
    @errors = response['errors']
    user = if response['user']
                           response['user']
                         elsif !@errors
                           interface.get(route)['user']
                         end
    return Log.warn(@errors) if @errors
    user.each { |k, v| instance_variable_set("@#{k}", v)}
  end
end