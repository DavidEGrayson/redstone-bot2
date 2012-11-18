require_relative 'spec_helper'

describe TestBot do
  before do
    @bot = TestBot.new_at_position(RedstoneBot::Coords[0, 64, 0])
  end

  it "does not use any real threads" do
    Thread.list.should have(1).items
  end
end