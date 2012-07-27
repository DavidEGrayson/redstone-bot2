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
end