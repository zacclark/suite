# encoding: utf-8
module Suite
  def test_task_group string, &block
    puts "called from module"
  end
  
  class Runner
    def initialize name, &block
      Printer.write "Running Suite for #{name}:"
      
      instance_eval(&block)
    end
    
    def test_task_group string, &block
      block.call
    end
    
    def execute command
      Printer.write("#{command} ... ", completed: false)
      output = `#{command} 2>&1`
      success = $?.success?
      if success
        Printer.write("✓", completed: true, color: :green)
      else
        Printer.write("✖", completed: true, color: :red)
        Printer.write(output)
      end
    end
  end
end