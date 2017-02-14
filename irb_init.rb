Dir["lib/helpers/*.rb", "lib/*.rb", "lib/recipe/*.rb", "groups/*.rb", "lib/storage/*.rb"].each {|file| require Dir.pwd + '/' + file }
