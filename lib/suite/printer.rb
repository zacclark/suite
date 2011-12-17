module Suite
  class Printer
    class << self
      def write string, options = {}
        if options[:color]
          string = colorize(string, options[:color])
        end
        
        if options[:completed] != false
          puts "#{@indent}#{string}"
        else
          print "#{@indent}#{string}"
        end
      end
      
      def colorize(text, color_code)
        codes = {
          red: "\e[31m",
          green: "\e[32m"
        }
        "#{codes[color_code]}#{text}\e[0m"
      end
      
      def increase_indent
        @indent ||= ""
        @indent += "  "
      end
      
      def decrease_indent
        @indent ||= ""
        @indent = @indent.sub("  ", '')
      end
    end
  end
end