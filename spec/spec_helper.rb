require 'rubygems'
Bundler.require(:default)

Dir["lib/helpers/*.rb", "lib/helpers/storage/*.rb", "lib/*.rb", "lib/recipe/*.rb", "groups/*.rb", "lib/storage/*.rb", "groups/test_cases/*.rb", "lib/billing/*.rb"].each {|file| require Dir.pwd + '/' + file }


RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true

  c.before :each do |x|
    test_name = "#{x.metadata[:example_group][:full_description]} #{x.description}"
    puts "\n" + '=' * test_name.size
    puts test_name
    puts '=' * test_name.size
  end

  if ENV['DEBUG']
    c.after :each do |x|
      binding.pry if x.exception
    end
  end
end

#Turn on this flag to run CDN related spec
$deliveryOn = true
