require_relative 'spec_helper'
require_relative 'test_bot'

describe TestBot do
  before do
    @bot = TestBot.new
    @bot.start_bot
  end

  it "does not use any real threads" do
    Thread.list.should have(1).items
  end
end