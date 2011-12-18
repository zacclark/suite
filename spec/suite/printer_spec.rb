require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Suite::Printer do
  before do
    Suite::Printer.unstub(:write)
  end
  
  describe "write" do
    it "should print a string given" do
      string = "hello"
    
      Suite::Printer.should_receive(:puts).with(string)
      Suite::Printer.write(string)
    end
  
    it "should print without newline" do
      string = "hello"
    
      Suite::Printer.should_receive(:print).with(string)
      Suite::Printer.write(string, completed: false)
    end
  
    it "should colorize strings" do
      string = "something"
    
      Suite::Printer.should_receive(:colorize).with(string, :red).and_return("fake_output")
      Suite::Printer.should_receive(:puts).with("fake_output")
      Suite::Printer.write(string, color: :red)
    end
    
    it 'should allow for skipping indentation' do
      string = "something"
      Suite::Printer.increase_indent
      Suite::Printer.increase_indent
      Suite::Printer.increase_indent
      Suite::Printer.should_receive(:puts).with(string)
      Suite::Printer.write(string, skip_indent: true)
      Suite::Printer.decrease_indent
      Suite::Printer.decrease_indent
      Suite::Printer.decrease_indent
    end
    
    it "should allow you to print to a string" do
      Suite::Printer.should_not_receive(:puts)
      Suite::Printer.should_not_receive(:print)
      Suite::Printer.write("something", to_string: true).should == "something"
    end
  end
  
  describe "colorize" do
    it "should accept different :red" do
      Suite::Printer.colorize("something", :red).should == "\e[31msomething\e[0m"
    end
    
    it "should accept different :green" do
      Suite::Printer.colorize("something", :green).should == "\e[32msomething\e[0m"
    end
  end
  
  describe "increase_indent" do
    it "should increase the indent level for anything printed after" do
      Suite::Printer.increase_indent
      Suite::Printer.should_receive(:puts).with("  something")
      Suite::Printer.write("something")
    end
  end
  
  describe "descrease_indent" do
    it "should lower the indent level by one" do
      Suite::Printer.class_eval("@indent = ''")
      Suite::Printer.increase_indent
      Suite::Printer.decrease_indent
      Suite::Printer.should_receive(:puts).with("something")
      Suite::Printer.write("something")
    end
  end

end