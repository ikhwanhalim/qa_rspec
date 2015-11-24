Bundler.require(:default)
Dir["lib/helpers/*.rb", "lib/*.rb", "groups/*.rb"].each {|file| require Dir.pwd + '/' + file }