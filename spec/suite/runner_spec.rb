require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Suite::Runner do
  describe "Basic instanstiation of test suite" do
    it "should run the code block passed to it" do
      lamb = lambda {}
      lamb.should_receive(:call)
      
      block = Proc.new do
        lamb.call
      end
      
      Suite::Runner.new "suite name", &block
    end
  
    it "should print info about the run" do
      Suite::Printer.unstub(:print)
      Suite::Printer.should_receive(:print).with("Running Suite for Example Test:")
    
      Suite::Runner.new "Example Test" do
      end
    end 
  end
  
  describe "helpers" do
    it "should provide the ability to group tests" do
      block = lambda {}
      block.should_receive(:call)
      Suite::Runner.new "test runner" do
        test_task_group "name", &block
      end
    end
    
    describe "#execute" do
      it "should be callable" do
        Suite::Runner.any_instance.should_receive(:'`').with("bundle exec rspec spec")
        `true`
        Suite::Runner.new "test runner" do
          test_task_group "name", do
            execute "bundle exec rspec spec"
          end
        end
      end
      
      it "should print the output of the command if it exited false" do
        Suite::Runner.any_instance.should_receive(:'`').with("bundle exec rspec spec").and_return("the output")
        `false`
        Suite::Printer.should_receive(:print).with("the output")
        Suite::Runner.new "test runner" do
          test_task_group "name", do
            execute "bundle exec rspec spec"
          end
        end
      end
    end

  end
end
