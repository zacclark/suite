# encoding: utf-8
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
      Suite::Printer.unstub(:write)
      Suite::Printer.should_receive(:write).with("running suite for Example Test:")
      Suite::Printer.should_receive(:write)
      Suite::Printer.should_receive(:increase_indent)
      Suite::Printer.should_receive(:decrease_indent)
      Suite::Runner.new "Example Test" do
      end
    end
    
    it "should increase the indent level around the suite" do
      Suite::Runner.new "Example Test" do
      end
    end
    
    it "should exit(false) if anything reports failure" do
      Suite::Runner.any_instance.unstub(:report_failure)
      expect {
        Suite::Runner.new "test runner" do
          group "name" do
            report_failure
          end
        end
      }.to exit_with_code(1)
    end
    
    describe "suite finished" do
      it "should print a green success message if nothing failed" do
        time = Time.now
        Time.stub(:now).and_return(time)
        Suite::Runner.new "Example Test" do
        end
      end
    end
  end
  
  describe "helpers" do
    describe "group" do
      it "should provide the ability to group tests" do
        block = lambda {}
        block.should_receive(:call)
        Suite::Runner.new "test runner" do
          group "name", &block
        end
      end
      
      it "should print the group name" do
        Suite::Runner.new "test runner" do
          Suite::Printer.should_receive(:write).with("running group name:")
          group "name" do
          end
        end
      end
      
      it "should change indent level around the block" do
        Suite::Runner.new "test runner" do
          Suite::Printer.should_receive(:increase_indent)
          Suite::Printer.should_receive(:decrease_indent).at_least(1)
          group "name" do
          end
        end
      end
    end
    
    describe "#execute" do
      it "should be callable" do
        Suite::Runner.any_instance.should_receive(:spin_until_done).any_number_of_times.with({string: nil, command: "bundle exec rspec spec"}).and_return(["", true])
        Suite::Runner.new "test runner" do
          group "name", do
            execute "bundle exec rspec spec"
          end
        end
      end
      
      it "should print the output of the command if it exited false" do
        Suite::Runner.any_instance.should_receive(:spin_until_done).any_number_of_times.with({string: nil, command: "bundle exec rspec spec"}).and_return(["the output", false])
        Suite::Printer.should_receive(:write).with("the output")
        Suite::Runner.new "test runner" do
          group "name", do
            execute "bundle exec rspec spec"
          end
        end
      end
      
      it "should print the command it is running and a green checkmark if it succeeds" do
        Suite::Printer.should_receive(:write).with("bundle exec rspec spec ... ", completed: false, color: :blue, to_string: true).and_return('fake')
        Suite::Runner.any_instance.should_receive(:spin_until_done).with({string: 'fake', command: "bundle exec rspec spec"}).and_return(["the output WOOOOO", true])
        Suite::Printer.should_receive(:write).with("✓", completed: true, color: :green, skip_indent: true)
        Suite::Runner.new "test runner" do
          group "name", do
            execute "bundle exec rspec spec"
          end
        end
      end
      
      it "should print the command it is running and a red X if it fails" do
        Suite::Printer.should_receive(:write).with("bundle exec rspec spec ... ", completed: false, color: :blue, to_string: true).and_return('fake')
        Suite::Runner.any_instance.should_receive(:spin_until_done).with({string: 'fake', command: "bundle exec rspec spec"}).and_return(["the output", false])
        Suite::Printer.should_receive(:write).with("✖", completed: true, color: :red, skip_indent: true)
        Suite::Runner.new "test runner" do
          group "name", do
            execute "bundle exec rspec spec"
          end
        end
      end
      
      it "should call report_failure if the command exits without success" do
        Suite::Runner.any_instance.should_receive(:report_failure)
        Suite::Runner.new "test runner" do
          group "name", do
            execute "false"
          end
        end
      end
    end
  end
end
