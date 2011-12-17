require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Suite::Printer do
  before do
    Suite::Printer.unstub(:print)
  end
  
  it "should print a string given" do
    string = "hello"
    
    $stdout.should_receive(:puts).with(string)
    Suite::Printer.print(string)
  end
end
