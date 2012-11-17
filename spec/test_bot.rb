# The TestBot class is like the Bot class, but some of the details of
# threads, timeouts, and condition variables and such will be changed to make
# it easier to test.

require 'redstone_bot/bots/bot'
require_relative 'test_brain'
require_relative 'test_client'
require_relative 'test_synchronizer'

class TestBot < RedstoneBot::Bot
  include NullSynchronizer

  def initialize
    super(TestClient.new)
  end

  def setup
    super
  
    @brain = TestBrain.new(self)
    @mutex = nil
  end
end