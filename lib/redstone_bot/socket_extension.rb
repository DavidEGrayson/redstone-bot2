module RedstoneBot
  module SocketExtension
    def read_byte
      read(1).unpack('C')[0]
    end

    def read_short
      read(2).unpack('s>')[0]
    end

    def read_int
      read(4).unpack('l>')[0]
    end

    def read_long
      read(8).unpack('q>')[0]
    end

    def read_float
      read(4).unpack('g')[0]
    end

    def read_double
      read(8).unpack('G')[0]
    end

    def read_string_raw
      read(read_short * 2).force_encoding('UCS-2BE')
    end

    def read_string
      read_string_raw.encode("UTF-8")
    end
  end
end