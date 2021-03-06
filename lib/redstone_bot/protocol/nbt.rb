module RedstoneBot
  module NBT
    module Reader
      def read_nbt
        tags = {}
        while b = read(1)
          tag_id = b.ord
          break if tag_id == 0
          
          name = read_string_utf8
          raise "Non-unique tag name #{name}" if tags[name]        
          tags[name] = read_nbt_payload(tag_id)
        end
        tags
      end
      
      def read_nbt_payload(tag_id)
        case tag_id
        when 1 then read_byte
        when 2 then read_short
        when 3 then read_int
        when 8 then read_string_utf8
        when 9
          subtag_id = read_byte
          read_int.times.collect { read_nbt_payload(subtag_id) }
        when 10 then read_nbt
        else
          raise "Unknown tag id #{tag_id}."
        end
      end
      
    end
 
    module Encoder
      def nbt(data)
        s = "".force_encoding("BINARY")
        data.each_pair do |name, value|
          s += nbt_tag(name, value)
        end
        s
      end
      
      def nbt_tag(name, value)
        tag_id = nbt_possible_tag_ids(value).first
        byte(tag_id) + string_utf8(name) + nbt_payload(tag_id, value)
      end
      
      def nbt_possible_tag_ids(value)
        case value
        when Integer
          case value
          when -0x80..0x7F then [1, 2, 3]
          when -0x8000..0x7FFFF then [2, 3]
          when -0x8000_0000..0x7FFF_FFFF then [3]
          end
        when String then [8]
        when Array then [9]  # TODO: consider using byte_array (7) or int_array (11)
        when Hash then [10]
        end or raise ArgumentError, "Unrecognized input #{value.inspect}"
      end
      
      def nbt_payload(tag_id, value)
        case tag_id
        when 1 then byte(value)
        when 2 then short(value)
        when 8 then string_utf8(value)
        when 9 then
          possible_subtag_ids = value.collect(&method(:nbt_possible_tag_ids)).inject(:&)
          subtag_id = possible_subtag_ids.first or raise ArgumentError, "Incompatible list elements."
          byte(subtag_id) + int(value.size) + value.collect { |s| nbt_payload(subtag_id, s) }.join
        when 3 then int(value)
        when 10 then nbt(value) + "\x00"
        else raise ArgumentError, "Unknown tag id #{tag_id}."
        end
      end
    end
  end
end