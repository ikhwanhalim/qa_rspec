class SshKey
  attr_reader :interface, :user, :user_id, :key, :id

  def initialize(user)
    @user = user
    @interface = user.interface
    @key = `cat ~/.ssh/*.pub`.chomp
  end

  def add_ssh_key
    response_handler interface.post("/users/#{user.id}/ssh_keys", { ssh_key: { key: key } })
  end

  def remove_ssh_key
    interface.delete("/settings/ssh_keys/#{id}")
  end

  private

  def response_handler(response)
    ssh_key = response['ssh_key'] if response['ssh_key']
    ssh_key.each { |k, v| instance_variable_set("@#{k}", v)}
  end
end