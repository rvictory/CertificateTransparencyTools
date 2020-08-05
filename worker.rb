require "bunny"
require_relative 'lib/work_item'
require_relative 'lib/ctl_api_manager'
require_relative 'lib/file_output_handler'

WORK_QUEUE = "ctl_download_work"
conn = Bunny.new
conn.start

channel = conn.create_channel
queue  = channel.queue(WORK_QUEUE)
exchange  = channel.default_exchange

FileOutputHandler.set_output_dir "output"

managers = {}

queue.subscribe do |delivery_info, metadata, payload|
  work_item = WorkItem.new_from_hash(JSON.parse(payload))
  unless managers.has_key?(work_item.url)
    managers[work_item.url] = CTLAPIManager.new(work_item.url, work_item.name)
  end
  manager = managers[work_item.url]
  begin
    results = manager.get_parsed_entries(work_item.begin_index, work_item.end_index - work_item.begin_index + 1)
    FileOutputHandler.write_batch(work_item.url, "Name", work_item.begin_index, work_item.end_index, results)
    puts "Wrote batch: #{work_item.to_hash.inspect}"
  rescue Exception => e
    puts "Failed to process batch #{work_item.inspect}: #{e.message}"
    puts e.backtrace.join("\n")
      #failed_batches.push(work_item)
  end
end

loop do

end