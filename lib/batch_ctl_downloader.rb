require_relative "ctl_api_manager"

class BatchCTLDownloader

  def initialize(ctl_url, name, output_handler, num_threads=10)
    @ctl_url = ctl_url
    @name = name
    @output_handler = output_handler
    manager = CTLAPIManager.new(ctl_url, name)
    @batch_size = manager.get_max_batch_size
    @cert_count = manager.get_cert_count
    @num_threads = num_threads
  end

  def download_all
    download_range(0, @cert_count - 1)
  end

  def download_range(start_index, end_index)
    count = end_index - start_index + 1 # Convert from 0 based to real count
    queue = Queue.new
    num_batches = count / @batch_size
    puts "Using #{num_batches} batches"
    left_overs = count % @batch_size

    num_batches.times do |i|
      start = start_index + (i * @batch_size)
      finish = start + @batch_size - 1
      #puts "Start: #{start}, Finish: #{finish}"
      queue.push(WorkBatch.new(start, finish))
    end

    if left_overs > 0
      queue.push(WorkBatch.new(end_index - left_overs, end_index))
      num_batches += 1
    end

    completed_batches = 0
    mutex = Mutex.new
    threads = []
    failed_batches = []

    @num_threads.times do
      t = Thread.new do
        manager = CTLAPIManager.new(@ctl_url, @name)
        while true
          work_item = queue.pop
          begin
            results = manager.get_parsed_entries(work_item.start_index, work_item.end_index - work_item.start_index + 1)
            @output_handler.write_batch(@ctl_url, @name, work_item.start_index, work_item.end_index, results)
          rescue Exception => e
            puts "Failed to process batch #{work_item.inspect}: #{e.message}"
            failed_batches.push(work_item)
          end
          mutex.synchronize do
            completed_batches += 1
          end
        end
      end
      threads.push(t)
    end

    puts "Beginning download"
    while completed_batches < num_batches
      puts "#{completed_batches}/#{num_batches} - #{completed_batches * 1.0 / num_batches * 100}% Complete (downloaded #{completed_batches * @batch_size} items)"
      sleep 5
    end

    # Kill the threads
    threads.each do |thread|
      Thread.kill(thread)
    end
  end

end

class WorkBatch

  attr_reader :start_index, :end_index

  def initialize(start_index, end_index)
    @start_index = start_index
    @end_index = end_index
  end

end

