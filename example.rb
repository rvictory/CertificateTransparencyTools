require "net/http"
require "uri"
require_relative './lib/ctl_parser'
require_relative './lib/ctl_api_manager'

start_index = 2000
num_entries_to_pull = 10

log_url = "ct.googleapis.com/logs/xenon2020/"
log_url = "ct.cloudflare.com/logs/nimbus2023/"

manager = CTLAPIManager.new(log_url, "Cloudflare 'Nimbus2023' Log")

puts "Available certificates for #{log_url}: #{manager.get_cert_count}"
results = manager.get_parsed_entries(start_index, num_entries_to_pull)
puts "Retrieved #{results.length} results"
puts JSON.pretty_unparse(results)
