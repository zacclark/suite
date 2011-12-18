# encoding: utf-8
module Suite
  class Runner
    def initialize name, &block
      @failure = false
      
      Printer.write "running suite for #{name}:"
      
      Printer.increase_indent
      instance_eval(&block)
      Printer.decrease_indent
      if @failure
        exit(false)
      else
        Printer.write("✓ suite finished successfully at #{Time.now.strftime("%H:%M on %Y-%m-%d")}", color: :green)
      end
    end
    
    def group string, &block
      Printer.write("running group #{string}:")
      Printer.increase_indent
      block.call
      Printer.decrease_indent
    end
    
    def report_failure
      @failure = true
    end
    
    def execute command
      Printer.write("#{command} ... ", completed: false, color: :blue)
      output = `#{command} 2>&1`
      success = $?.success?
      if success
        Printer.write("✓", completed: true, color: :green, skip_indent: true)
      else
        Printer.write("✖", completed: true, color: :red, skip_indent: true)
        Printer.write(output)
        report_failure
      end
    end
  end
end