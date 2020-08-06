require "json"
require "net/http"
require_relative "./curb_pool"
require_relative 'ctl_parser'

class CTLAPIManager

  def initialize(ctl_url, name)
    @ctl_url = ctl_url
    @ctl_url_uri = URI.parse("https://" + @ctl_url)
    @name = name
    @pool = CurbPool.new(10)
    @http_object = nil
    @mutex = Mutex.new
  end

  def get_cert_count
    request_url = "https://#{@ctl_url}ct/v1/get-sth"
    #puts "Using URL #{request_url}"
    uri = URI.parse(request_url)
    begin
      request_data = Net::HTTP.get_response(uri)
      data = JSON.parse(request_data.body)
      data["tree_size"]
    rescue
      nil
    end
  end

  def get_raw_entries(start_index, num_entries_to_pull)
    request_url = "https://#{@ctl_url}ct/v1/get-entries?start=#{start_index}&end=#{start_index + num_entries_to_pull - 1}"
    #uri = URI.parse(request_url)
    #if @http_object.nil?
    #  @http_object = Curl::Easy.new
    #end
    #@mutex.synchronize do
    #  @http_object.url = request_url
    #  @http_object.perform
    #  JSON.parse(@http_object.body_str)
    #end
    JSON.parse(@pool.request(request_url))
  end

  def get_raw_entries_old(start_index, num_entries_to_pull)
    request_url = "https://#{@ctl_url}ct/v1/get-entries?start=#{start_index}&end=#{start_index + num_entries_to_pull - 1}"
    uri = URI.parse(request_url)
    if @http_object.nil?
      @http_object = Net::HTTP.start(uri.host, uri.port, :use_ssl => true)
    end
    request = Net::HTTP::Get.new uri.request_uri
    JSON.parse(@http_object.request(request).body)
  end

  def get_parsed_entries(start_index, num_entries_to_pull)
    start = Time.now.to_f
    data = get_raw_entries(start_index, num_entries_to_pull)
    finish = Time.now.to_f
    #puts "Took #{finish - start} seconds to download the raw entries"
    start = Time.now.to_f
    to_return = CTLParser.parse(@ctl_url, @name, start_index, data)
    finish = Time.now.to_f
    #puts "Took #{finish - start} seconds to parse the raw entries"
    to_return
  end

  def get_max_batch_size
    get_raw_entries(0, 3000)["entries"].length
  end

end