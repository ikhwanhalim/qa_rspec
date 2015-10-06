require 'helpers/api_client'

class Settings
  include ApiClient
  attr_accessor :cfg

  def initialize
    auth unless self.conn
  end

  def get_config
    response = get("/settings/configuration")
    @cfg = response['settings']
  end

  def edit_config(data = nil)
    params = {:restart => "1"}
    params[:configuration] = data
    puts params
    put("/settings", params)
    Log.info("Waiting 20 seconds for restarting settings.")
    sleep(20)
    get_config
  end
end