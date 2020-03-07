require_relative 'output_handler'

class FileOutputHandler < OutputHandler

  def self.set_output_dir(dir)
    @@dir = dir
  end

  def self.write_batch(ctl_url, name, start_index, end_index, data)
    cleaned_filename = ctl_url.gsub("/", "_")
    puts "Received batch from #{ctl_url} s: #{start_index} e: #{end_index} data length: #{data.length}"
    File.open(File.join(@@dir,"#{cleaned_filename}_#{start_index}-#{end_index}.json"), "w") {|f| f.puts data.map {|x| x.to_json}.join("\n")}
  end
end