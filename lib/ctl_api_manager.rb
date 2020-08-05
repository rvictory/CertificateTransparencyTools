require "json"
require "net/http"
require_relative 'ctl_parser'

class CTLAPIManager

  def initialize(ctl_url, name)
    @ctl_url = ctl_url
    @name = name
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
    uri = URI.parse(request_url)
    request_data = Net::HTTP.get_response(uri)
    data = request_data.body
    JSON.parse(data)
  end

  def get_parsed_entries(start_index, num_entries_to_pull)
    data = get_raw_entries(start_index, num_entries_to_pull)
    CTLParser.parse(@ctl_url, @name, start_index, data)
  end

  def get_max_batch_size
    get_raw_entries(0, 3000)["entries"].length
  end

end