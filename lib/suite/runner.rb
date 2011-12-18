# encoding: utf-8
module Suite
  class Runner
    def initialize name, opts = {}, &block
      @options = {
        characters: {
          success: "✓",
          failure: "✖"
        },
        colors: {
          success: :green,
          command: :blue,
          failure: :red
        }
      }.merge(opts)
      
      @failure = false
      
      Printer.write "running suite for #{name}:"
      
      Printer.increase_indent
      instance_eval(&block)
      Printer.decrease_indent
      if @failure
        exit(false)
      else
        Printer.write("#{@options[:characters][:success]} suite finished successfully at #{Time.now.strftime("%H:%M on %Y-%m-%d")}", color: @options[:colors][:success])
      end
    end
    
    def group string, &block
      Printer.write("running group #{string}:")
      Printer.increase_indent
      block.call
      Printer.decrease_indent
    end
    
    def report_failure
      @failure = true
    end
    
    def execute command
      string = Printer.write("#{command} ... ", completed: false, color: @options[:colors][:command], to_string: true)
      
      output, success = spin_until_done(string: string, command: command)
      
      if success
        Printer.write(@options[:characters][:success], completed: true, color: @options[:colors][:success], skip_indent: true)
      else
        Printer.write(@options[:characters][:failure], completed: true, color: @options[:colors][:failure], skip_indent: true)
        Printer.write(output)
        report_failure
      end
    end
    
    def spin_until_done(opts = {})
      options = {
        string: "Spin ",
        time: 0.1,
        spinner_characters: %W( | / - \\ )
      }.merge(opts)
  
      #pipe set up
      readPipe, writePipe = IO.pipe

      pid = Process.fork do        
        readPipe.close
        
        writePipe.write(if options[:command]
          {
            blockOutput: `#{options[:command]} 2>&1`,
            exitStatus: $?.success?
          }.to_json
        elsif block_given?
          {
            blockOutput: nil,
            exitStatus: !!yield
          }.to_json
        else
          {}.to_json
        end)
        
        writePipe.close
      end
  
      writePipe.close
  
      options[:spinner_characters].to_enum.cycle do |character|
        begin
          Process.getpgid( pid )
        rescue Errno::ESRCH
          break
        end
    
        system( 'echo "$(tput cuu 1)"' )
        $stdout.print "#{options[:string]}#{character}"
        sleep(options[:time])
      end
  
      # end line for spinner with just string
      system( 'echo "$(tput cuu 1)"' )
      $stdout.print options[:string]
  
      ret = readPipe.read
      outputReturn = JSON.parse(ret)
  
      return outputReturn["blockOutput"], outputReturn["exitStatus"]
    end
  end
end