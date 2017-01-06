class User
  attr_reader :interface, :id, :billing_plan_id, :errors

  def initialize(interface)
    @interface = interface
  end

  def find(user_id)
    response_handler interface.get("/users/#{user_id}")
  end

  def add_ssh_key(ssh_key)
    response = interface.post("#{route}/ssh_keys", { ssh_key: { key: ssh_key } })
    response_handler response
    return if response['errors']
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