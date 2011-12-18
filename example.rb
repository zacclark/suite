$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'suite'

Suite::Runner.new "my tests" do
  group "simple" do
    execute "true"
    # execute "cd 234rwefhskfdj"
  end
  
  group "nested" do
    group "inside" do
      execute "ls"
      execute "ruby -e 'sleep(1)'"
    end
  end
end