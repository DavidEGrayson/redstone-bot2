# The TestBot class is like the Bot class, but some of the details of
# threads, timeouts, and condition variables and such will be changed to make
# it easier to test.

require 'redstone_bot/bots/bot'
require_relative 'test_brain'
require_relative 'test_client'
require_relative 'test_synchronizer'
require_relative 'test_body'

class TestBot < RedstoneBot::Bot
  include TestSynchronizer

  def initialize
    super(TestClient.new)
  end

  def setup_mutex
    # No mutex for testing.
  end
  
  def setup_body
    @body = TestBody.new(client, self)
  end
  
  def setup_brain
    @brain = TestBrain.new(self)
  end
end