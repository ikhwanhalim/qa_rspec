class Run < ActiveRecord::Base
  attr_accessible :files, :templates, :title, :virt, :server, :threads
  has_many :reports, dependent: :destroy
  
  validates :title, :files, :server, :threads, presence: true

  def self.thread(server, report)
  	template = Template.where(template_name: report.template_name).first
  	files = YAML.load(report.spec_files)
  	report.report_file ||= Report.file_ident
  	report.save
  	str_run = "SERVER='#{server}' "\
              "VIRT_TYPE='#{report.virt}' "\
              "TEMPLATE_FILE_NAME='#{template.template_name}' "\
              "TEMPLATE_URL='#{template.template_url}' "\
              "rspec #{files.join ' '} --format h --out reports/#{Report.today}/#{report.report_file}"
    # p str_run
	  Spawnling.new do
      Report.find(report.id).update_attribute(:status, "Running")
      system str_run
      Report.find(report.id).update_attribute(:status, "Finished")
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
