
module RedstoneBot
  # Vulnerabilities:
  #   Thread.new { while true; end }
  #   "eval " + string
  #   EvaluatesRuby.instance_method(:handle_chat).bind(self).call(message)
  class ChatEvaluator
    def initialize(client)
      @client = client
      client.listen do |p|
        if p.is_a?(UserChatMessage) && message.contents =~ /^eval (.+)/
          do_eval $1
        end
      end
    end
  
    def do_eval(string)
      result = nil
      thread = Thread.new do
        $SAFE = 4
        result = begin
          eval string
        rescue Exception => e
          e.message
        end
      end
      if !thread.join(0.5)
        thread.kill
        result = ":("
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