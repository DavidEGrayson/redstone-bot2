require_relative 'spec_helper'
require_relative 'packet_spec'
require 'redstone_bot/entity_tracker'

describe RedstoneBot::EntityTracker do
  before do
    @client = TestClient.new
    @entity_tracker = described_class.new(@client, nil)
  end
  
  it "tracks dropped items" do
    
  end
  
end