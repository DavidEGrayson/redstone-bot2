# Mimics the RedstoneBot::Client class.
# Used for testing classes that interact directly with the client.
class TestClient
  def initialize
    @listeners = []
  end
  
  def listen(&proc)
    @listeners << proc
  end
  
  def <<(packet)
    @listeners.each do |l|
      l.call packet
    end
  end
  
  def username
    "testbot"
  end
  
  def time_string
    "FLEEMSDAY"   # http://dilbert.com/strips/comic/2012-07-25
  end
  
  def next_action_number   # TODO: instead of duplicating code, share a module with the real Client class
    @last_action_number ||= 0  # cannot use an enumerator we use this cross-thread 
    if @last_action_number < 0xFFFF
      @last_action_number += 1
    else
      @last_action_number = 1
    end
  end
end