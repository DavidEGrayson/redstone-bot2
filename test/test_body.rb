# TODO: get rid of this TestBody class.  It's OK to just override the one method
# we want to change in spec_helper.rb
class TestBody < RedstoneBot::Body
  
  undef announce_received_position  # throws a nice exception
  def announce_received_position(packet)
    # Don't print that stuff in tests.
  end
end