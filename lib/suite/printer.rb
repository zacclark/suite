module Suite
  class Printer
    class << self
      def write string, options = {}
        if options[:color]
          string = colorize(string, options[:color])
        end
        
        string = "#{@indent}#{string}" unless options[:skip_indent]
        
        if options[:completed] != false
          puts string
        else
          print string
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

