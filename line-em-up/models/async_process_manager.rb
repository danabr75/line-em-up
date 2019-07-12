# require 'concurrent'
require 'parallel'
# require 'ruby-progressbar'
# require 'time'
# require 'benchmark/ips'
# require 'open3'

require "thwait"

class AsyncProcessManager

  def initialize thread_type_klass, threads, list_is_hash = false, use_processes = false
    @thread_type_klass = thread_type_klass
    @use_processes = use_processes
    # @processor_count = 2
    @processor_count = threads
    @list_is_hash = list_is_hash
    Thread.abort_on_exception = true
  end

  def update window, items, *args
    if !@use_processes
      Thread.new do
        if @list_is_hash
          Parallel.each(items, in_threads: 8) do |key, item|
            @thread_type_klass.update(window, item, args)
            # rand(255)
          end
        else
          Parallel.each(items, in_threads: 8) do |item|
            @thread_type_klass.update(window, item, args)
            # rand(255)
          end
        end
      end
    end

    # Marshal.load
    # Just don't work.. SLOW FPS, projectiles aren't being updated.
    if @use_processes
      final_data = []
      r, w = IO.pipe

      pids = []

      # parameter_datas = [{fun1: 123}, {fun2: 234}]
      parameter_threads = []
      items.each do |key, item|
        t = Thread.new do
          # testvar = item.get_data
          # puts "TEST VAR"
          # puts testvar.inspect
          # test2var = Marshal.dump(testvar)
          # puts "TEST2"
          # puts test2var.inspect
          # puts Marshal.load(test2var)
          # puts "HERE WE GO"
          # Thread.current[:pid] = Process.spawn({"MARSHALLED_DATA"=>Marshal.dump(item.get_data)}, RbConfig.ruby, "#{SCRIPT_DIRECTORY}/async_projectile_update_script.rb", :out => w, :err => [:child, :out])
          Thread.current[:pid] = Process.spawn({"MARSHALLED_DATA" => item.get_data.to_json, "ARGS" => args.to_json }, RbConfig.ruby, "#{SCRIPT_DIRECTORY}/async_projectile_update_script.rb", :out => w, :err => [:child, :out])
          Thread.exit
        end
        parameter_threads << t
      end

      ThreadsWait.all_waits(parameter_threads) do |t|
        pids << t[:pid]
      end

      w.close

      pid_threads = []

      pids.each do |pid|
        t = Thread.new do
          pid, status = Process.wait2(pid)
          Thread.current[:status] = status
          # Thread.current[:pid]    = pid
          # data = Marshal.load(r.gets)
          Thread.exit
        end
        pid_threads << t
      end

      child_process_raw_data = []

      puts "pid_threads.count: #{pid_threads.count}"

      # ThreadsWait.all_waits(pid_threads)
      ThreadsWait.all_waits(pid_threads) do |t|
        # puts "#{t} complete."
        if t[:status] == 0
          puts "THREAD ENDED SUCCESSFULLY"
        else
          puts "THREAD EXITED WITH FAILURE"
        end
      end


      File.open('testoutput', 'w') do |file|
        while (line = r.read) && line != ''
          puts "INCOMING DATA:"
          puts line.inspect
          puts line.class
          file.write(line)
          begin
            data = JSON.parse(line)
            puts 'FOUND DATA'
            puts data.inspect
            final_data << data
          rescue JSON::ParserError => e  
            # Random issues with parsing..
          end
        end
        puts "Ending While Loop"
      end

      r.close




      puts "What did we get?"
      puts final_data.inspect
      final_data.each do |f_data|
        puts "DOES ITEMS HAVE KEY? #{items.key?(f_data["id"])}  --- #{f_data}"
        items[f_data['id']].set_data(f_data)
      end
      puts "EDN HERE"

    end

  end
end