class User
  attr_reader :interface, :id, :billing_plan_id, :errors, :ssh_key

  def initialize(interface)
    @interface = interface
    @ssh_key = SshKey.new(self)
  end

  def find(user_id)
    response_handler interface.get("/users/#{user_id}")
  end

  def add_ssh_key
    response = @ssh_key.add_ssh_key
    return if response['errors']
  end

  def remove_ssh_key
    @ssh_key.remove_ssh_key
  end

  def route
    "/users/#{id}"
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