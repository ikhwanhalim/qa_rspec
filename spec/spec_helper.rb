require 'rubygems'
Bundler.require(:default)
Dir["lib/helpers/*.rb", "lib/*.rb", "lib/recipe/*.rb", "groups/*.rb"].each {|file| require Dir.pwd + '/' + file }

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
end