require_relative 'spec_helper'

describe TestBot do
  before do
    @bot = TestBot.new
    @bot.start_bot
  end

  it "does not use any real threads" do
    Thread.list.should have(1).items
  end
end