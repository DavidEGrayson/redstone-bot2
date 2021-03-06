require_relative '../protocol/packets'

module RedstoneBot

  class ChatEvaluator
    attr_accessor :permission_denied_message
    attr_accessor :safe_level
    attr_accessor :timeout
  
    def initialize(client, context)
      @context = context
      @client = client
      @permission_denied_message = "I'm sorry %s, but I cannot do that."
      @safe_level = 4
      @timeout = 0.5
    
      client.listen do |p|
        next unless p.is_a?(Packet::ChatMessage)

        next unless p.chat =~ /^eval (.+)/
        str = $1
        
        do_eval str
      end
    end
  
    def do_eval(string)
      result = nil
      exception = nil
      thread = Thread.new do
        $SAFE = @safe_level
        result = begin
          (@context || self).instance_eval string
        rescue Exception => e
          exception = e
          e.message
        end
      end
      if !thread.join(timeout)
        thread.kill
        result = ":("
      end

      if exception
        $stderr.puts exception.message, exception.backtrace
      end
      
      begin
        case result
          when String then chat result
          when nil then
          else chat result.inspect
          end
      rescue SecurityError => e
        chat e.message
      end

      GC.enable
    end
    
    protected
    def chat(message)
      @client.chat(message)
    end
  end
  
end