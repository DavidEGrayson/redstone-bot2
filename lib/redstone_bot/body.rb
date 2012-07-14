module RedstoneBot
  class Body
    def initialize(client)
      client.listen do |p|
        raise "body received #{p.inspect}"
      end
    end
  end
end