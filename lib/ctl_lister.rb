require "json"
require "net/http"
require "uri"
require_relative 'ctl_api_manager'

module CTLLister

  def self.get_available_ctls(include_max_size=false)
    request_url = "https://www.gstatic.com/ct/log_list/log_list.json"
    uri = URI.parse(request_url)
    begin
      request_data = Net::HTTP.get_response(uri)
      data = JSON.parse(request_data.body)
      operators = {}
      data["operators"].each do |operator|
        operators[operator["id"]] = operator["name"]
      end

      to_return = []

      data["logs"].each do |log|
        operator = log["operated_by"].map {|x| operators[x]}.join(", ")
        log["operated_by"] = operator
        if include_max_size
          manager = CTLAPIManager.new(log["url"], log["description"])
          log["max_batch_size"] = manager.get_max_batch_size
        end
        to_return.push(CTL.new_from_hash(log))
          #pp to_return.last
      end

      to_return
    rescue
      []
    end
  end

end

class CTL

  attr_reader :operated_by, :key, :url, :description, :maximum_merge_delay, :max_batch_size

  def initialize(description, key, url, maximum_merge_delay, operated_by, max_batch_size=nil)
    @description = description
    @key = key
    @url = url
    @maximum_merge_delay = maximum_merge_delay
    @operated_by = operated_by
    @max_batch_size = max_batch_size
  end

  def self.new_from_hash(hash)
    CTL.new(hash["description"], hash["key"], hash["url"], hash["maximum_merge_delay"], hash["operated_by"], hash["max_batch_size"])
  end

end