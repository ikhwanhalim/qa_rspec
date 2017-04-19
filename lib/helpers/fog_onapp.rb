# Use this when need FogOnapp
# module FogOnapp
#   CONF = ENV['CONF_PATH'] || 'config/conf.yml'

#   def compute
#     FogOnapp.compute
#   end

#   def self.compute
#     @compute ||= -> {
#       data = YAML::load_file(CONF)
#       params = {provider: 'OnApp', user: data['user'], key: data['pass'],uri: data['url']}
#       Fog::Compute.new(params)
#     }.call
#   end
# end