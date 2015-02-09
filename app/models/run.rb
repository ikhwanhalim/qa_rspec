class Run < ActiveRecord::Base
  attr_accessible :files, :templates, :title, :virt, :server, :threads
  has_many :reports, dependent: :destroy
  
  validates :title, :files, :server, :threads, presence: true

  def self.thread(server, report)
  	template = Template.where(manager_id: report.template_name).first
  	files = YAML.load(report.spec_files)
  	report.report_file ||= Report.file_ident
  	report.save
    full_report_path = "reports/#{Report.today}/#{report.report_file}"
  	str_run = "SERVER='#{server}' "\
  	          "LOG_FILE='#{report.report_file}' "\
              "VIRT_TYPE='#{report.virt}' "\
              "TEMPLATE_MANAGER_ID='#{template.manager_id}' "\
              "rspec #{files.join ' '} --format h --out #{full_report_path}"
    p str_run
	  Spawnling.new do
      report_by_id = Report.find(report.id)
      report_by_id.update_attribute(:status, "Running")
      system str_run
      report_by_id.update_attribute(:status, "Finished")
    end
  end

  def self.errors_handler(params)
    errors = Hash.new
    params.each do |key, value|
      if value.blank?
        errors[key] = "can't be blank!"
      end
    end
    return errors
  end

  def self.directory_hash(path, name=nil)
    data = {:data => (name || path)}
    data[:children] = children = []
    Dir.foreach(path) do |entry|
      next if (entry == '..' || entry == '.')
      full_path = File.join(path, entry)
      if File.directory?(full_path)
        children << directory_hash(full_path, entry)
      else
        children << path + '/' + entry
      end
    end
    return data
  end

  def self.render_hash(hash, html=nil)
    html ||= ''
    hash.each do |h|
      html << "<div class='arrow-right'></div>"
      html << "<label class='folder'>#{h[:data].upcase}</label><ul>"
      if h[:children].first.kind_of? Hash
        render_hash(h[:children], html)
      else
        h[:children].each do |c|
          cb = "<input class='checkbox' type='checkbox' name='files[]' value='#{c}'>"
          html << "<li>#{cb}<label>#{c.split('/').last}</label></li>"
        end
        html << "</ul><br>"
      end
    end
    html
  end

end
