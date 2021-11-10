require_relative 'spec_helper'
require 'redstone_bot/trackers/entity_tracker'
require 'redstone_bot/models/coords'

describe RedstoneBot::Mob do
  let (:eid) { 44 }
  let (:unrecognized_type) { ?? }
  
  it "creates an instance of Mob if it doesn't recognize the type" do
    mob = RedstoneBot::Mob.create(unrecognized_type, eid, RedstoneBot::Coords[3, 4, 5])
    expect(mob.class).to eq(RedstoneBot::Mob)
  end
end