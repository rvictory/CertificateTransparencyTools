require "json"

class WorkItem

  attr_reader :url, :name, :begin_index, :end_index
  def initialize(url, begin_index, end_index, name)
    @url = url
    @begin_index = begin_index
    @end_index = end_index
    @name = name
  end

  def self.new_from_hash(hash)
    WorkItem.new(hash["url"], hash["begin_index"], hash["end_index"], hash["name"])
  end

  def to_hash
    {
        :url => @url,
        :begin_index => @begin_index,
        :end_index => @end_index,
        :name => @name
    }
  end
end