module RedstoneBot
  class PacketPrinter
    def initialize(source, matchers, file=$stderr)
      source.listen do |event|
        if matchers.any? { |m| m === event }
          file.puts event
        end
      end
    end
  end
end