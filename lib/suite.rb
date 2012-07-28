$LOAD_PATH.unshift(File.dirname(__FILE__))

require "benchmark"

class Suite
	def initialize
		@tasks = []
		@timing = false
		@callbacks = {
			success: [],
			failure: []
		}
	end

	def task(command)
		@tasks << command
	end

	def timing(set)
		if [true, :on, :yes, :true].include? set
			@timing = true
		end
	end

	def on_failure(&block)
		@callbacks[:failure] << block
	end

	def on_success(&block)
		@callbacks[:success] << block
	end

	def banner(message, symbol, color = :green)
		puts symbol.to_s*80
		puts " #{message} ".center(80, symbol)
		puts symbol.to_s*80
	end

	def run!
		@failed_tasks = []
		@task_times = []

		@tasks.each do |task|
			puts " #{task} ".center(80, "=")
			time = Benchmark.realtime do
				@failed_tasks << task unless system(task)
			end
			@task_times << {task: task, time: time}
		end

		puts

		if @timing
			total_time = @task_times.inject(0) {|memo, details| memo + details[:time]}
			puts "Suite ran in #{_format_time(total_time)}"

			@task_times.sort_by{|details| details[:time]}.reverse.each do |details|
				print "  #{_format_time(details[:time])} ".rjust(6)
				print "- #{details[:task]}\n"
			end
		end

		puts


		if @failed_tasks.empty?
			@callbacks[:success].each(&:call)

			return 0
		else
			puts "Failed tasks:"
			@failed_tasks.each do |failed|
				puts "  #{failed}"
			end

			puts

			@callbacks[:failure].each(&:call)

			return 1
		end
	end

	private

	def _format_time(seconds)
		seconds = seconds.to_i
		minutes = 0
		while seconds > 60
			minutes += 1
			seconds -= 60
		end
		if minutes > 0
			"#{minutes}m#{seconds}s"
		else
			"#{seconds}s"
		end
	end
end