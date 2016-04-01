require 'net/http'
require 'json'

if ARGV[0] == 'template'
  templates = JSON.parse Net::HTTP.get('templates-manager.onapp.com', '/')
  manager_ids = templates.map { |t| t.values[0]['manager_id'] }
  manager_ids.select! do |id|
    ARGV[1] == 'windows' ? id =~ /^win[\d]/ : id !~ /^win[\d]/
  end
  puts manager_ids.sample
elsif ARGV[0] == 'virt'
  puts %w(xen3 xen4 kvm5 kvm6).sample
end