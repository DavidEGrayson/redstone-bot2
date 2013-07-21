require_relative 'spec_helper'
require 'redstone_bot/trackers/time_tracker'

describe RedstoneBot::TimeTracker do
  before do
    @client = TestClient.new
    @time_tracker = described_class.new(@client)
  end
  
  context "initially" do
    specify { @time_tracker.world_age.should == nil }
    specify { @time_tracker.day_age.should == nil }
    specify { @time_tracker.sun_moving?.should == nil }
    specify { @time_tracker.night?.should == nil }
    specify { @time_tracker.day?.should == nil }
    specify { @time_tracker.ticks_until_night.should == nil }
    specify { @time_tracker.seconds_until_night.should == nil }
    specify { @time_tracker.ticks_until_day.should == nil }
    specify { @time_tracker.seconds_until_day.should == nil }
    specify { @time_tracker.time_known?.should == false }
  end
  
  context "after getting a packet with non-negative times" do
    let(:world_age) { 1234567901 }
    let(:day_age) { 8000 }
    
    before do
      @client << RedstoneBot::Packet::TimeUpdate.create(world_age, day_age)
    end
    
    specify { @time_tracker.world_age.should == world_age }
    specify { @time_tracker.day_age.should == day_age }
    specify { @time_tracker.sun_moving?.should == true }
    specify { @time_tracker.time_known?.should == true }
  end
  
  context "after getting a packet with negative day age" do
    let(:world_age) { 99999999 }
    let(:day_age) { -8000 }
    
    before do
      @client << RedstoneBot::Packet::TimeUpdate.create(world_age, day_age)
    end
    
    specify { @time_tracker.world_age.should == world_age }
    specify { @time_tracker.day_age.should == day_age.abs }
    specify { @time_tracker.sun_moving?.should == false }
    specify { @time_tracker.time_known?.should == true }
  end
  
  def set_day_age(day_age)
    @time_tracker.instance_variable_set:@day_age, day_age
  end

  context "when the sun is present" do
    before do
      set_day_age 3000
    end
    
    specify { @time_tracker.should_not be_night }
    specify { @time_tracker.should be_day }
    specify { @time_tracker.ticks_until_night.should == 9000 }
    specify { @time_tracker.seconds_until_night.should eq BigDecimal("450")  }
    specify { @time_tracker.ticks_until_day.should == 0 }
    specify { @time_tracker.seconds_until_day.should eq BigDecimal("0") }
  end
  
  context "at night" do
    before do
      set_day_age 12998
    end
    
    specify { @time_tracker.should be_night }
    specify { @time_tracker.should_not be_day }
    specify { @time_tracker.ticks_until_night.should == 0 }
    specify { @time_tracker.seconds_until_night.should eq BigDecimal("0") }
    specify { @time_tracker.seconds_until_night.should eq 0 } #tmphax
    specify { @time_tracker.ticks_until_day.should == 11002 }
    specify { @time_tracker.seconds_until_day.should eq BigDecimal("550.1") }
  end
end