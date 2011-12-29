# encoding: utf-8
module Suite
  
  # class for running a block or shell command on a new process
  #   default spin behavior is a stdout visual spinner while
  #   the process is running
  class Spinner
    attr_accessor :exit_status, :block_output, :ruby_error,
                  :spin_block, :process_block, :final_block
    
    # outputs
    @exit_status
    @block_output
    @ruby_error
    
    # internal state
    @is_bash_command
    @spin_iteration
    @process_ID
    @started
    @finished
    @spinner_string
    @spinner_characters
    
    # communication
    @read_pipe
    @write_pipe
    
    # blocks
    @spin_block
    @process_block
    @final_block
    
    
    ########## Readonly Properties ###########
    
    def has_started
      return @started
    end
    
    def has_finished
      if @finished # do we know?
        return true
      elseif @process_ID != nil # could have finished since last spin call
        begin
          Process.getpgid( @process_ID )
          return false
        rescue Errno::ESRCH
          return @finished = true
        end
      else # don't have a process at this point, hasn't started
        return false
      end
    end
    
    ########## State Methods ###########
    
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
      
      # set initial internal state
      @spin_iteration = 0
      @started = false
      @finished = false
      @process_ID = nil
      @spinner_characters = options[:spinner_characters]
      @spinner_string = options[:spinner_string]
      
      # set blocks
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
    end # initilize
    
    
    # reset object state so it can be run again
    #  returns reset success (true/false)
    def reset_state
      begin
        Process.getpgid( @process_ID )
        return false # process is still running if we get here
      rescue Errno::ESRCH
      end
      @read_pipe, @write_pipe = IO.pipe
      @spin_iteration = 0
      @started = false
      @finished = false
      @process_ID = nil
      @block_output = nil
      @exit_status = nil
      @ruby_error = nil
      return true
    end
    
    ########## Run Methods ###########
    
    # starts the block process
    def start
      if !@started
        @started = true
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
        @write_pipe.close # close write pipe TO the new process so we don't hang
      end # if !@started
    end # start
    
    
    # Spins the current thread until the spinner process is finished 
    #   or opts[:max_time] seconds have elapsed
    # @spin_block will get called every opts[:wait_time] seconds
    def spin (opts = {} )
      options = {
        wait_time: 0.1,
        max_time: -1
      }.merge(opts)
      
      if !@started 
        self.start
      end
      
      start_time = Time.now.to_f
      until @finished
        if options[:max_time] > 0
          if ( Time.now.to_f - start_time ) >= options[:max_time]
            break
          end
        end
        
        begin
          Process.getpgid(@process_ID)
          # the process is running, spin more
          @spin_block.call(@spin_iteration)
          sleep(options[:wait_time])
          @spin_iteration += 1
        rescue Errno::ESRCH
          @finished = true
        end
      end # until @finished
      
      if @finished
        @final_block.call
        output_return = Marshal::load( @read_pipe.read )
        
        @block_output = output_return[:block_output]
        @exit_status = output_return[:exit_status]
        @ruby_error = output_return[:ruby_error]
      end # if done
      
      return self # convinience for calling new spinner in one line
    end # spin
  end # class Spinner
end # module Suite


# example usage
#spinner1 = Suite::Spinner.new(spinner_string: "Spin me!... ") do
#    sleep(3)
#    evil.cheese
#end.spin
#
#puts spinner1.block_output
#puts spinner1.exit_status
#puts spinner1.ruby_error
#puts ''
#
#spinner2 = Suite::Spinner.new({spinner_string: "Spin me!... "}, 'ls').spin
#
#puts spinner2.exit_status