# encoding: utf-8
module Suite
  
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
        spinner_characters: %W( | / - \\ ),
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
      @spinner_characters = options[:spinner_characters]
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
      
      # pipe set up
      @read_pipe, @write_pipe = IO.pipe
      @spin_iteration = 0
    end # initilize
    
    
    def spin_until_done(opts = {})
      options = {
        wait_time: 0.1
      }.merge(opts)
      
      self.fork_block
      
      @write_pipe.close
      self.spin_for_current_process( {wait_time: options[:wait_time]} )
      
      @final_block.call
      output_return = Marshal::load( @read_pipe.read )
      
      @block_output = output_return[:block_output]
      @exit_status = output_return[:exit_status]
      @ruby_error = output_return[:ruby_error]
      return self
    end
    
    
    def reset_state
      @read_pipe, @write_pipe = IO.pipe
      @spin_iteration = 0
    end
    
    ########## Utility Methods ###########

    def fork_block
      @process_ID = Process.fork do
        @read_pipe.close
        hash_for_pipe = {
          exit_status: true
        }
        begin
          block_value = @process_block.call
        rescue => error
          hash_for_pipe[:ruby_error] = error
          hash_for_pipe[:exit_status] = false
        end
        hash_for_pipe[:block_output] = block_value
        
        if @is_bash_command
          hash_for_pipe[:exit_status] = $?.success?
        end
        @write_pipe.write(Marshal::dump( hash_for_pipe ))
        @write_pipe.close
      end
    end # fork_block
    
    
    def spin_for_current_process (opts = {} )
      options = {
        wait_time: 0.1,
        max_time: -1
      }.merge(opts)
      
      start_time = Time.now.to_f
      done = false
      until done
        if options[:max_time] > 0
          if ( Time.now.to_f - start_time ) >= options[:max_time]
            break
          end
        end
        
        begin
          Process.getpgid( @process_ID )
          done = false
          rescue Errno::ESRCH
          done = true
        end
        
        @spin_block.call(@spin_iteration)
        
        sleep(options[:wait_time])
        @spin_iteration += 1
      end
    end # spin_for_current_process
  end
end


# example usage
#spinner1 = Suite::Spinner.new(spinner_string: "Spin me!... ") do
#    sleep(3)
#    evil.cheese
#end.spin_until_done
#
#puts spinner1.block_output
#puts spinner1.exit_status
#puts spinner1.ruby_error
#puts ''
#
#spinner2 = Suite::Spinner.new({spinner_string: "Spin me!... "}, 'ls').spin_until_done
#
#puts spinner2.exit_status