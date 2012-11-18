require_relative 'test_synchronizer'
require 'redstone_bot/synchronizer'

describe NullSynchronizer do
  RedstoneBot::Synchronizer.instance_methods.each do |method_name|
    describe "#{method_name} method" do
      let(:test_method) { NullSynchronizer.instance_method(method_name) }
      let(:original_method) { RedstoneBot::Synchronizer.instance_method(method_name) }

      it "exists" do
        test_method.should be
      end
    
      it "has the same signature as the original method" do
        test_method.parameters.should == original_method.parameters
      end
    end
  end
  
end