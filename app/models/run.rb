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
              "VIRT_TYPE='#{report.virt}' "\
              "TEMPLATE_MANAGER_ID='#{template.manager_id}' "\
              "rspec #{files.join ' '} --format h --out #{full_report_path}"
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

end
