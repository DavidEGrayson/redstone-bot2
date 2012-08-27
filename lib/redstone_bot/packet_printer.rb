module RedstoneBot
  class PacketPrinter
    def initialize(source, matchers, file=$stderr)
      source.listen do |event|
        if matchers.any? { |m| m === event }
          file.puts source.time_string + " " + event.to_s
        end
      end
    end
  end
end