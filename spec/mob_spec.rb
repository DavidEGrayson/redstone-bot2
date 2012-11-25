require_relative 'spec_helper'
require 'redstone_bot/trackers/entity_tracker'

describe RedstoneBot::Mob do
  let (:eid) { 44 }
  let (:unrecognized_type) { ?? }
  
  it "creates an instance of Mob if it doesn't recognize the type" do
    mob = RedstoneBot::Mob.create(unrecognized_type, eid)
    mob.class.should == RedstoneBot::Mob
  end
end