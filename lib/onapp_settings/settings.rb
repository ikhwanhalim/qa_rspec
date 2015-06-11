require 'helpers/onapp_http'

class Settings
  include OnappHTTP
  attr_accessor :config

  def initialize
    auth unless self.conn
  end

  def get_config
    response = get("/settings/configuration")
    return response['settings']
  end

  def edit_config(data = nil)
    params = {:restart => "1"}
    params[:configuration] = data
    puts params
    response = put("/settings", params)
    Log.info("Waiting 20 seconds for restarting settings.")
    sleep(20)
    return response
  end
end