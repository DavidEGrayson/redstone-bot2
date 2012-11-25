# Mimics the RedstoneBot::Client class.
# Used for testing classes that interact directly with the client.
require 'redstone_bot/client'
require_relative 'test_synchronizer'

class TestClient < RedstoneBot::Client
  attr_accessor :synchronizer, :sent_packets

  def initialize
    @listeners = []
    @synchronizer = TestStandaloneSynchronizer.new  # gets overridden by TestBot
    @sent_packets = []
    @last_packets = [nil]*4   # keep track of last 4 packets
    @packets_received = 0
  end
  
  def listen(&proc)
    @listeners << proc
  end
  
  def <<(packet)
    record_packet packet
    notify_listeners packet
  end
  
  def send_packet(packet)
    sent_packets << packet
  end
    
  def username
    "testbot"
  end
  
  def time_string
    "FLEEMSDAY"   # http://dilbert.com/strips/comic/2012-07-25
  end
  
  def start
    @connected = true
    notify_listeners :start
  end
end