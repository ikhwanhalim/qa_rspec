require "onapp_test"
require "pry"

describe "some basic test" do
    before :all do
        test = OnappTest.new
    end
    after :all do

    end
    it "hello" do
        binding.pry()
    end
end

