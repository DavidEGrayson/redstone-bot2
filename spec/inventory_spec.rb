require_relative 'spec_helper'
require 'redstone_bot/inventory'

# monkeypatch to make tests more readable
class RedstoneBot::ItemType
  def *(count)
    raise ArgumentError.new("count must be an integer larger then 0") unless count > 0
    RedstoneBot::Slot.new(self, count)
  end
end

module RedstoneBot
class ItemType  # do this to make the class names more readable

describe RedstoneBot::Inventory do
  before do
    @client = TestClient.new
    @inventory = described_class.new(@client)
  end
  
  it "ignores SetWindowItems packets for non-0 windows" do
    @client << Packet::SetWindowItems.create(2, [Bread * 10]*45)
    @inventory.slots.should == [nil]*45
    @inventory.should_not be_loaded
  end
  
  context "before being loaded" do  
    it "has nil slots" do
      @inventory.slots.should == [nil]*45
    end
  
    it "is not loaded" do
      @inventory.should_not be_loaded
    end
    
    it "is empty" do
      @inventory.should be_empty
    end
    
    it "is pending" do
      @inventory.should be_pending
    end
  end
  
  context "after being loaded" do
    before do
      slots = [nil]*45
      slots[10] = IronShovel * 1
      slots[36] = WheatItem * 31
      slots[37] = Bread * 44
      @client << Packet::SetWindowItems.create(0, slots)
    end

    it "is loaded" do
      @inventory.should be_loaded
    end
    
    it "is not empty" do
      @inventory.should_not be_empty
    end
    
    it "has stuff in the slots" do
      @inventory.slots[36].item_type.should == WheatItem
      WheatItem.should === @inventory.slots[36]
    end
    
    it "can select a slot to hold" do
      @client.should_receive(:send_packet).with(Packet::HeldItemChange.new(3))
      @inventory.select_hotbar_slot 3
    end
        
    it "has a nice include? method" do
      @inventory.should include IronShovel
      @inventory.should include WheatItem
      @inventory.should include Bread
      @inventory.should_not include EmeraldOre      
    end
    
    it "has a nice hotbar_include? method" do
      @inventory.should_not be_hotbar_include(IronShovel)
      @inventory.should be_hotbar_include(Bread)
    end
  end
  
end

end; end  # break out of the class and module