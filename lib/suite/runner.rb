module Suite
  def test_task_group string, &block
    puts "called from module"
  end
  
  class Runner
    def initialize name, &block
      Printer.print "Running Suite for #{name}:"
      
      instance_eval(&block)
    end
    
    def test_task_group string, &block
      block.call
    end
    
    def execute command
      output = `#{command}`
      success = $?.success?
      Printer.print(output) unless success
    end
  end
end