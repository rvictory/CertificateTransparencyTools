# Works through a directory and compacts all of the files that have been downloaded in small batches
require "fileutils"
require 'date'

base_dir = ENV['BASE_DIR'] || "/data/output/"

Dir.entries(base_dir).each do |entry|
  next if [".", ".."].include?(entry) || !File.directory?(entry)
  puts "Compacting #{entry}"
  path = File.join(base_dir, entry)
  Dir.chdir(path)
  FileUtils.mkdir_p(File.join(path, "rotate"))
  puts `mv ./*.json rotate/`
  Dir.chdir(File.join(path, "rotate"))
  filename = Time.now.strftime("%Y-%m-%d_%H%M%S")
  puts `cat ./*.json > #{filename}.json`
  puts `gzip #{filename}.json`
  puts `rm -f ./*.json`
end