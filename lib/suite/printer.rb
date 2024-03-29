module Suite
  class Printer
    class << self
      def write string, options = {}
        if options[:color]
          string = colorize(string, options[:color])
        end
        
        string = "#{@indent}#{string}" unless options[:skip_indent]
        
        return string if options[:to_string]
        
        if options[:completed] != false
          puts string
        else
          print string
        end
      end
      
      def colorize(text, color_code)
        codes = {
          red: 31,
          green: 32,
          blue: 34,
          cyan: 36
        }
        "\e[#{codes[color_code]}m#{text}\e[0m"
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

