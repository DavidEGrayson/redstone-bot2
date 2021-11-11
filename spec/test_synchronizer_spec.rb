require 'test_synchronizer'
require 'redstone_bot/synchronizer'

describe TestSynchronizer do
  RedstoneBot::Synchronizer.instance_methods.each do |method_name|
    describe "#{method_name} method" do
      let(:test_method) { TestSynchronizer.instance_method(method_name) }
      let(:original_method) { RedstoneBot::Synchronizer.instance_method(method_name) }

      it "exists" do
        expect(test_method).to be
      end
    
      it "has the same signature as the original method" do
        expect(test_method.parameters).to eq(original_method.parameters)
      end
    end
  end
  
end