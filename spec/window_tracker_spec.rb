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
  end
  
  context "after a chest is opened" do
    before do
      subject << RedstoneBot::Packet::OpenWindow.create(2, 0, "container.chest", 27)
    end
    
    it { should be_open }
    it { subject.window_id.should == 2 }
    
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

    it "has the right slots" do
      slots = [nil]*27
      slots[0] = RedstoneBot::ItemType::Emerald * 30
      slots[4] = RedstoneBot::ItemType::WheatItem * 4
      slots[26] = RedstoneBot::ItemType::DiamondBlock * 1
      subject.slots.should == slots
    end
    
    context "after closing" do
      before do
        subject << RedstoneBot::Packet::CloseWindow.create(2)
      end
      
      it { should_not be_open }      
      it { subject.window_id.should == nil }
    end

  end  
end