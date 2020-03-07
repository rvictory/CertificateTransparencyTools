class OutputHandler
  def self.write_batch(ctl_url, name, start_index, end_index, data)
    raise Exception.new "Must be implemented by subclasses"
  end
end