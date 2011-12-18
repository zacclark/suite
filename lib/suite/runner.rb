# encoding: utf-8
module Suite
  def group string, &block
    puts "called from module"
  end
  
  class Runner
    def initialize name, &block
      Printer.write "running suite for #{name}:"
      
      Printer.increase_indent
      instance_eval(&block)
      Printer.decrease_indent
      exit(false) if @failure
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
      Printer.write("#{command} ... ", completed: false)
      output = `#{command} 2>&1`
      success = $?.success?
      if success
        Printer.write("✓", completed: true, color: :green, skip_indent: true)
      else
        Printer.write("✖", completed: true, color: :red, skip_indent: true)
        Printer.write(output)
      end
    end
  end
end