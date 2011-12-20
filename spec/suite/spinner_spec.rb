# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Suite::Spinner do
  describe "Data returned from" do
    describe "Task failures" do
      it "should contain exception description and failure status for invalid ruby" do
        spinner = Suite::Spinner.new do
          some_invalid_ruby_here_i_should_hope
        end.spin_until_done
        spinner.ruby_error.should include('undefined local variable or method `some_invalid_ruby_here_i_should_hope\' for ')
        spinner.exit_status.should == false
      end
      
      it "should contain block data and failure status for invalid bash"
    end # describe "Task failures"
    
    describe "Task success" do
      it "should contain success status for valid ruby" do
        spinner = Suite::Spinner.new do
          sleep(0.1)
        end.spin_until_done
        spinner.exit_status.should == true
      end
    end # describe "Task success"
  end # describe "Data returned from task"
end