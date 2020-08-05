require "bunny"
require "net/http"
require "uri"
require "json"
require_relative 'lib/ctl_parser'
require_relative 'lib/ctl_api_manager'
require_relative 'lib/ctl_lister'
require_relative 'lib/batch_ctl_downloader'
require_relative 'lib/file_output_handler'
require_relative 'lib/work_item'

puts "Listing Available CTLs"
ctls = CTLLister.get_available_ctls

WORK_QUEUE = "ctl_download_work"
conn = Bunny.new
conn.start

channel = conn.create_channel
queue  = channel.queue(WORK_QUEUE)
exchange  = channel.default_exchange

ctls.each do |ctl|
  manager = CTLAPIManager.new(ctl.url, ctl.key)
  count = manager.get_cert_count
  batch_size = manager.get_max_batch_size

  #queue = Queue.new
  num_batches = count / batch_size
  puts "Using #{num_batches} batches"
  left_overs = count % batch_size

  start_index = 0

  num_batches.times do |i|
    start = start_index + (i * batch_size)
    finish = start + batch_size - 1
    #puts "Start: #{start}, Finish: #{finish}"
    exchange.publish(WorkItem.new(ctl.url, start, finish, ctl.key).to_hash.to_json, :routing_key => queue.name)
  end

  if left_overs > 0
    exchange.publish(WorkItem.new(ctl.url, end_index - left_overs, end_index, ctl.key).to_hash.to_json, :routing_key => queue.name)
    num_batches += 1
  end

  puts "Pushed #{num_batches} batches to the queue for URL #{ctl.url}"

end
