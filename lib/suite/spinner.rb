# encoding: utf-8
module Suite
  require 'json'
  
  class Spinner
    attr_accessor :exit_status, :block_output, :ruby_error
    
    @exit_status
    @block_output
    @ruby_error
    
    @is_bash_command
    @spin_iteration
    @process_ID
    @read_pipe
    @write_pipe
    
    @spinner_string
    @spinner_characters
    
    @spin_block
    @process_block
    @final_block
    
    
    def initialize( opts = {}, bash_command = '', &block)
      options = {
        spinner_string: "Spin... ",
        spin_block: lambda {|iteration|
          system( 'echo "$(tput cuu 1)"' )
          spinner_character_index = iteration % @spinner_characters.length
          $stdout.print @spinner_string + @spinner_characters[spinner_character_index]
        },
        final_block: lambda {
          # end line for spinner with just string
          system( 'echo "$(tput cuu 1)"' )
          $stdout.print @spinner_string + " "
        }
      }.merge(opts)
      
      # option changable
      @spinner_characters = %W( | / - \\ )
      @spinner_string = options[:spinner_string]
      
      @spin_block = options[:spin_block]
      @final_block = options[:final_block]
      
      if bash_command == ''
        @process_block = block
        @is_bash_command = false
        else
        @process_block = lambda {
          eval("`#{bash_command} 2>&1`")
        }
        @is_bash_command = true
      end
      
      
      #pipe set up
      @read_pipe, @write_pipe = IO.pipe
      @spin_iteration = 0
    end #initilize
    
    
    def reset_state
      @read_pipe, @write_pipe = IO.pipe
      @spin_iteration = 0
    end
    
    
    def fork_ruby_block
      @process_ID = Process.fork do
        @read_pipe.close
        write_string = {
          exit_status: true
        }
        
        begin 
          block_value = @process_block.call
        rescue => error_detail
          write_string[:ruby_error] = error_detail
          write_string[:exit_status] = false
        end
        
        write_string[:block_output] = block_value
        
        @write_pipe.write(write_string.to_json)
        @write_pipe.close
      end 
    end # fork_ruby_block
    
    
    def fork_command_block
      @process_ID = Process.fork do
        @read_pipe.close
        
        block_value = @process_block.call
        
        write_string = {
          exit_status: $?.success?,
          block_output: block_value
        }.to_json
        
        @write_pipe.write(write_string)
        @write_pipe.close
      end
    end
    
    
    def spin_for_current_process (opts = {} )
      options = {
        time: 0.1
      }.merge(opts)
      
      done = false
      until done
        begin
          Process.getpgid( @process_ID )
          done = false
          rescue Errno::ESRCH
          done = true
        end
        
        @spin_block.call(@spin_iteration)
        
        sleep(options[:time])
        @spin_iteration += 1
      end
    end
    
    
    def spin_until_done(opts = {})
      options = {
        time: 0.1
      }.merge(opts)
      
      if @is_bash_command
        self.fork_command_block
        else
        self.fork_ruby_block
      end
      
      @write_pipe.close
      self.spin_for_current_process
      
      @final_block.call
      output_return = JSON.parse(@read_pipe.read)
      
      @block_output = output_return["block_output"]
      @exit_status = output_return["exit_status"]
      @ruby_error = output_return["ruby_error"]
      
      return self
    end
  end
end


# example usage
#spinner1 = Spinner.new(spinner_string: "Spin me!... ") do
#    sleep(3)
#    evil.cheese
#end.spin_until_done

#puts spinner1.block_output
#puts spinner1.exit_status
#puts spinner1.ruby_error

#spinner2 = Spinner.new({spinner_string: "Spin me!... "}, 'ls').spin_until_done

#puts spinner2.exit_status