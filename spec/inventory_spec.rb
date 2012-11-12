require_relative 'spec_helper'
require 'redstone_bot/trackers/inventory'

# do this to make the class and constant names in RedstoneBot and ItemType not
# require prefixes, thus making them more readable
module RedstoneBot
class ItemType  

describe Inventory do
  before do
    @client = TestClient.new
    @inventory = described_class.new(@client)
  end
  
  it "ignores SetWindowItems packets for non-0 windows" do
    @client << Packet::SetWindowItems.create(2, [Bread * 10]*45)
    @inventory.slots.should == [nil]*45
    @inventory.should_not be_loaded
  end
        
  it "can select a slot to hold" do
    @client.should_receive(:send_packet).with(Packet::HeldItemChange.new(3))
    @inventory.select_hotbar_slot 3
    @inventory.instance_variable_get(:@selected_hotbar_slot_index).should == 3
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
      slots[12] = Bread * 2
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
    
    it "is not pending" do
      @inventory.should_not be_pending
    end
    
    it "has stuff in the slots" do
      @inventory.slots[36].item_type.should == WheatItem
      WheatItem.should === @inventory.slots[36]
    end
        
    it "has a nice include? method" do
      @inventory.should include IronShovel
      @inventory.should include WheatItem
      @inventory.should include Bread
      @inventory.should_not include EmeraldOre      
    end
    
    it "has a nice item_types method" do
      @inventory.item_types.should == [IronShovel, Bread, WheatItem]
    end
    
    it "can count items" do
      @inventory.count(Bread).should == 46
      @inventory.count(Emerald).should == 0
    end
    
    it "can count empty slots" do
      @inventory.empty_slot_count.should == 32
    end
    
    it "has a nice hotbar_include? method" do
      @inventory.should_not be_hotbar_include IronShovel
      @inventory.should be_hotbar_include Bread
    end
    
    it "knows that hotbar index 0 is selected by default" do
      @inventory.selected_slot.should == WheatItem * 31
    end
    
    it "can hold the item that is already selected without sending packets" do
      @client.should_not_receive :send_packet
      @inventory.hold(WheatItem).should == true
      @inventory.selected_slot.should == WheatItem * 31
      @inventory.should_not be_pending
    end
    
    it "can hold another item in the hotbar with a single packet" do
      @client.should_receive(:send_packet).with(Packet::HeldItemChange.new(1))
      @inventory.hold(Bread).should == true
      @inventory.selected_slot.should == Bread * 44
      @inventory.should_not be_pending
    end
    
    it "if there is an empty spot in the hotbar can hold an item not in the hotbar" do
      #@client.should_receive(:send_packet).with(Packet::ClickWindow.new(0, slot_id, false, action_number, true, slots[slot_id]))
      #@client.should_receive(:send_packet).with(Packet::HeldItemChange.new(2))
      @client.should_receive(:send_packet).exactly(2).times
      @inventory.hold(IronShovel).should == true
      @inventory.selected_slot.should == IronShovel * 1
      @inventory.should be_pending
    end
    
    it "can dump by slot id" do
    @client.should_receive(:send_packet).exactly(2).times
      @inventory.dump_slot_id(36)
      @inventory.count(WheatItem).should == 0
    @inventory.should be_pending
    end
    
    it "can dump by item type" do
      @client.should_receive(:send_packet).exactly(2).times
      @inventory.dump(Bread)
      @inventory.count(Bread).should == 44
      @inventory.should be_pending
    end
    
    it "can dump all of some item type" do
      @client.should_receive(:send_packet).exactly(4).times
      @inventory.dump_all(Bread)
      @inventory.count(Bread).should == 0
      @inventory.should be_pending
    end
    
    it "can dump all items" do
      @client.should_receive(:send_packet).exactly(8).times
      @inventory.dump_all
      @inventory.should be_empty
      @inventory.should be_pending
    end
    
    it "responds to SetSlot packets for window 0" do
      @client << Packet::SetSlot.create(0, 32, DiamondAxe * 1)
      @inventory.slots[32].should == DiamondAxe * 1
    end

    it "ignores SetSlot packets for non-0 windows" do
      @client << Packet::SetSlot.create(10, 32, DiamondAxe * 1)
      @inventory.slots[32].should == nil
    end
    
    it "can use up the selected item" do
      # This is called by other parts of the code after sending some packet that uses up
      # the selected item, so use_up_one does not send any packets of its own.
      @inventory.selected_slot.should == WheatItem * 31
      @inventory.use_up_one
      @inventory.selected_slot.should == WheatItem * 30
      @inventory.selected_slot -= 29
      @inventory.selected_slot.should == WheatItem * 1
      @inventory.use_up_one
      @inventory.selected_slot.should be nil     
    end
    
    context "when there are pending transactions" do
      before do
        @client.stub(:send_packet)
        @inventory.dump(Bread)
      end
      
      it "is pending" do
        @inventory.should be_pending
        @inventory.instance_variable_get(:@pending_actions).should == [1, 2]
      end

      it "can understand when they are confirmed" do
        @client << Packet::ConfirmTransaction.new(0, 1, true)
        @inventory.should be_pending
        @client << Packet::ConfirmTransaction.new(0, 2, true)
        @inventory.should_not be_pending
      end
      
      it "can understand when they are rejected" do
        @client << Packet::ConfirmTransaction.new(0, 1, false)
        @inventory.should be_pending
        @inventory.should_not be_loaded
        @inventory.slots.uniq.should == [nil]
      end
    end
  end
  
  context "when the entire inventory is full" do
    before do
      slots = [Cobblestone*64]*45
      slots[10] = IronOre * 1
      @client << Packet::SetWindowItems.create(0, slots)
    end
    
    it "can swap two items to put something in the hotbar" do
      @client.should_receive(:send_packet).exactly(3).times
      @inventory.hold(IronOre).should == true
      @inventory.selected_slot.should == IronOre * 1
      @inventory.should be_pending
    end
  end
  
end

end; end  # break out of the class and module