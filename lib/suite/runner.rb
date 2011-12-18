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
      Printer.write("#{command} ... ", completed: false, color: @options[:colors][:command])
      output = `#{command} 2>&1`
      success = $?.success?
      if success
        Printer.write(@options[:characters][:success], completed: true, color: @options[:colors][:success], skip_indent: true)
      else
        Printer.write(@options[:characters][:failure], completed: true, color: @options[:colors][:failure], skip_indent: true)
        Printer.write(output)
        report_failure
      end
    end
  end
end