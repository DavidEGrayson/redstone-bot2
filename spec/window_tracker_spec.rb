require_relative 'spec_helper'
require 'redstone_bot/trackers/window_tracker'

describe RedstoneBot::WindowTracker do
  subject { @window_tracker = RedstoneBot::WindowTracker.new(nil) }
  
  it "ignores random other packets" do
    subject << RedstoneBot::Packet::KeepAlive.new
  end
  
  context "initially" do
    it "is not open" do
      should_not be_open
    end
    
    it "has a nil window_id" do
      subject.window_id.should == nil
    end
  end
  
  context "after a chest is opened" do
    before do
      subject << RedstoneBot::Packet::OpenWindow.create(2, 0, "container.chest", 27)
    end
    
    it "is open" do
      should be_open
    end

    it "stores the window id" do
      subject.window_id.should == 2
    end
    
    it "can be closed" do
      subject << RedstoneBot::Packet::CloseWindow.create(2)
      subject.window_id.should == nil
      subject.should_not be_open
    end
  end
end