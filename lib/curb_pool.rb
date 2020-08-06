require "curb"

class CurbPool

  def initialize(num_instances=5)
    @queue = Queue.new
    num_instances.times { @queue.push(Curl::Easy.new) }
  end

  def request(url)
    to_return = nil
    curl = @queue.pop
    begin
      curl.url = url
      curl.perform
      to_return = curl.body_str
    rescue Exception => e
      puts "Exception while getting curb results: #{e.inspect}"
    end
    @queue.push(curl)
    to_return
  end

end