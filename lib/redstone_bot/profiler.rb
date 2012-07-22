require 'ruby-prof'

module RedstoneBot
  module Profiler    
    def run_time
      start = Time.now
      yield
      Time.now - start
    end
    
    def profile(&block)
      result = RubyProf.profile &block
      print_profile_result result
      result
    end
    
    def print_profile_result(result)
      File.open("profile.html", "w") do |file|
        RubyProf::GraphHtmlPrinter.new(result).print(file)
      end
    end
  end
end