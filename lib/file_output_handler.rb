require_relative 'output_handler'
require "fileutils"

class FileOutputHandler < OutputHandler

  def self.set_output_dir(dir)
    @@dir = dir
  end

  def self.write_batch(ctl_url, name, start_index, end_index, data)
    cleaned_filename = ctl_url.gsub("/", "_")
    #puts "Received batch from #{ctl_url} s: #{start_index} e: #{end_index} data length: #{data.length}"
    FileUtils.mkdir_p(File.join(@@dir, "/#{cleaned_filename}/"))
    File.open(File.join(@@dir, "/#{cleaned_filename}/", "#{cleaned_filename}_#{start_index}-#{end_index}.json.active"), "w") do |f|
      data.each do |row|
        retried = false
        begin
          f.puts row.to_json
        rescue Exception => e
          unless retried
            retried = true
            # We likely have an issue with UTF-8 domain names. Try to force a representation to keep the data
            row["leaf_cert"][:subject].keys.each do |key|
              row["leaf_cert"][:subject][key] = row["leaf_cert"][:subject][key].encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '') unless row["leaf_cert"][:subject][key].nil?
            end

            row["leaf_cert"][:extensions].keys.each do |key|
              row["leaf_cert"][:extensions][key] = row["leaf_cert"][:extensions][key].encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '') unless row["leaf_cert"][:extensions][key].nil?
            end

            new_domains = []
            row["leaf_cert"]["all_domains"].each do |domain|
              new_domains.push domain.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '') unless domain.nil?
            end
            row["leaf_cert"]["all_domains"] = new_domains

            new_chain = []
            row["chain"].each do |chain_cert|
              chain_cert[:subject].keys.each do |key|
                chain_cert[:subject][key] = chain_cert[:subject][key].encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '') unless chain_cert[:subject][key].nil?
              end

              chain_cert[:extensions].keys.each do |key|
                chain_cert[:extensions][key] = chain_cert[:extensions][key].encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '') unless chain_cert[:extensions][key].nil?
              end
              new_chain.push(chain_cert)
            end
            row["chain"] = new_chain

            retry
          end

          # @todo Write this to a file or something?
          puts "Failed to save #{row.inspect}: #{e.message}"
        end
      end
    end
    begin
      FileUtils.mv(File.join(@@dir, "/#{cleaned_filename}/", "#{cleaned_filename}_#{start_index}-#{end_index}.json.active"), File.join(@@dir, "/#{cleaned_filename}/", "#{cleaned_filename}_#{start_index}-#{end_index}.json"))
    rescue
    end
  end
end