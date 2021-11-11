require_relative 'spec_helper'
require 'redstone_bot/trackers/time_tracker'

describe RedstoneBot::TimeTracker do
  before do
    @client = TestClient.new
    @time_tracker = described_class.new(@client)
  end
  
  context "initially" do
    specify { expect(@time_tracker.world_age).to eq(nil) }
    specify { expect(@time_tracker.day_age).to eq(nil) }
    specify { expect(@time_tracker.sun_moving?).to eq(nil) }
    specify { expect(@time_tracker.night?).to eq(nil) }
    specify { expect(@time_tracker.day?).to eq(nil) }
    specify { expect(@time_tracker.ticks_until_night).to eq(nil) }
    specify { expect(@time_tracker.seconds_until_night).to eq(nil) }
    specify { expect(@time_tracker.ticks_until_day).to eq(nil) }
    specify { expect(@time_tracker.seconds_until_day).to eq(nil) }
    specify { expect(@time_tracker.time_known?).to eq(false) }
  end
  
  context "after getting a packet with non-negative times" do
    let(:world_age) { 1234567901 }
    let(:day_age) { 8000 }
    
    before do
      @client << RedstoneBot::Packet::TimeUpdate.create(world_age, day_age)
    end
    
    specify { expect(@time_tracker.world_age).to eq(world_age) }
    specify { expect(@time_tracker.day_age).to eq(day_age) }
    specify { expect(@time_tracker.sun_moving?).to eq(true) }
    specify { expect(@time_tracker.time_known?).to eq(true) }
  end
  
  context "after getting a packet with negative day age" do
    let(:world_age) { 99999999 }
    let(:day_age) { -8000 }
    
    before do
      @client << RedstoneBot::Packet::TimeUpdate.create(world_age, day_age)
    end
    
    specify { expect(@time_tracker.world_age).to eq(world_age) }
    specify { expect(@time_tracker.day_age).to eq(day_age.abs) }
    specify { expect(@time_tracker.sun_moving?).to eq(false) }
    specify { expect(@time_tracker.time_known?).to eq(true) }
  end
  
  def set_day_age(day_age)
    @time_tracker.instance_variable_set:@day_age, day_age
  end

  context "when the sun is present" do
    before do
      set_day_age 3000
    end
    
    specify { expect(@time_tracker).not_to be_night }
    specify { expect(@time_tracker).to be_day }
    specify { expect(@time_tracker.ticks_until_night).to eq(9000) }
    specify { expect(@time_tracker.seconds_until_night).to eq BigDecimal("450")  }
    specify { expect(@time_tracker.ticks_until_day).to eq(0) }
    specify { expect(@time_tracker.seconds_until_day).to eq BigDecimal("0") }
  end
  
  context "at night" do
    before do
      set_day_age 12998
    end
    
    specify { expect(@time_tracker).to be_night }
    specify { expect(@time_tracker).not_to be_day }
    specify { expect(@time_tracker.ticks_until_night).to eq(0) }
    specify { expect(@time_tracker.seconds_until_night).to eq BigDecimal("0") }
    specify { expect(@time_tracker.seconds_until_night).to eq 0 } #tmphax
    specify { expect(@time_tracker.ticks_until_day).to eq(11002) }
    specify { expect(@time_tracker.seconds_until_day).to eq BigDecimal("550.1") }
  end
end