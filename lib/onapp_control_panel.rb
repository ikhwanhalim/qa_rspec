require 'helpers/ssh'
require 'yaml'

class OnappControlPanel
  attr_reader :ip, :template_url, :version, :admin, :api_type, :template_path, :use_ssh_file_transfer, :ssh_file_transfer_server, :ssh_port

  def initialize
    puts 'Getting CP configaration'
    conf = YAML::load(open(File.expand_path(File.dirname(__FILE__) + '/../config/conf.yml')))
    @ip = ENV['SERVER'] || conf['ip']
    p ip
    @admin = "#{conf['login']}"
    @api_type = conf['api_type']
    @version = conf['versoin']
    connection = ssh_connection
    result = connection.exec!('cat /onapp/interface/config/on_app.yml || echo error')
    if result.split("\n").last.include?('error')
      puts "Failed get on_app.yml - #{result}"
      raise("Failed get on_app.yml - #{result}")
    else
      result.split("\n").each do |r|
        @template_path = r.gsub(/^.* /, '') if r.include?('template_path')
        @use_ssh_file_transfer = r.gsub(/^.* /, '') if r.include?('ssh_file_transfer_user')
        @ssh_file_transfer_server = r.gsub(/^.* /, '') if r.include?('ssh_file_transfer_server')
        @ssh_port = r.gsub(/^.* /, '') if r.include?('ssh_port')
      end
      connection.close
    end
  end
  def ssh_connection
    Ssh.start_with_keys(ip)
  end
end