require_relative 'spec_helper'
require 'redstone_bot/trackers/window_tracker'

describe RedstoneBot::WindowTracker do
  subject { RedstoneBot::WindowTracker.new(nil) }
  
  it "ignores random other packets" do
    subject << RedstoneBot::Packet::KeepAlive.new
  end
  
  context "initially" do
    it { should_not be_open }
    it { subject.window_id.should == nil }
    it { should_not be_loaded }
    it { subject.slots.should == nil }
  end
  
  context "after a chest is opened" do
    before do
      subject << RedstoneBot::Packet::OpenWindow.create(2, 0, "container.chest", 27)
    end
    
    it { should be_open }
    it { subject.window_id.should == 2 }
    it { should_not be_loaded }
    it { subject.slots.should == nil }

    it "ignores SetWindowItem packets for other windows" do
      subject << RedstoneBot::Packet::SetWindowItems.create(16, [nil, nil])
      subject.slots.should == nil
    end
  end

  context "after a chest is opened and the items are set" do
    before do
      subject << RedstoneBot::Packet::OpenWindow.create(2, 0, "container.chest", 27)
      slots = [nil]*27
      slots[0] = RedstoneBot::ItemType::Emerald * 30
      slots[4] = RedstoneBot::ItemType::WheatItem * 4
      slots[26] = RedstoneBot::ItemType::DiamondBlock * 1
      subject << RedstoneBot::Packet::SetWindowItems.create(2, slots)
    end
    
    it { should be_open }
    it { subject.window_id.should == 2 }
    it { should be_loaded }
    
    it "has the right slots" do
      slots = [nil]*27
      slots[0] = RedstoneBot::ItemType::Emerald * 30
      slots[4] = RedstoneBot::ItemType::WheatItem * 4
      slots[26] = RedstoneBot::ItemType::DiamondBlock * 1
      subject.slots.should == slots
    end
    
    it "responds to SetSlot packets" do
      subject << RedstoneBot::Packet::SetSlot.create(2, 0, nil)
      subject << RedstoneBot::Packet::SetSlot.create(2, 1, RedstoneBot::ItemType::GoldOre*64)
      subject.slots[0].should == nil
      subject.slots[1].should == RedstoneBot::ItemType::GoldOre*64
    end
    
    it "ignores SetSlot packets with wrong window_id" do
      subject << RedstoneBot::Packet::SetSlot.create(90, 0, nil)    
      subject.slots[0].should_not be_nil
    end
    
    context "after closing" do
      before do
        subject << RedstoneBot::Packet::CloseWindow.create(2)
      end
      
      it { should_not be_open }      
      it { subject.window_id.should == nil }
      it { should_not be_loaded }
      it { subject.slots.should == nil }
    end

  end  
end