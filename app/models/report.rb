class Report < ActiveRecord::Base
  attr_accessible :template_name, :spec_files, :virt, :run_id, :run, :report_file
  belongs_to :run

  def self.name_gen(name)
    name.gsub(/\ |tar|gz|xen|kvm|virtio|\.|\-/, '_').split("_").join("_")
  end

  def self.file_ident
   (0...12).map { (65 + rand(26)).chr }.join
  end

  def failed?
    report_page = Nokogiri::HTML(open(Rails.root + 'reports' + report_file))
    report_page.css(".failed").any? && status != "Failed" ? true : false
  end
end
