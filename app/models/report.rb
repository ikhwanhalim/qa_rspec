class Report < ActiveRecord::Base
  attr_accessible :template_name, :spec_files, :virt, :run_id, :run, :report_file
  belongs_to :run

  def self.name_gen(name)
    name.gsub(/\ |tar|gz|xen|kvm|virtio|\.|\-/, '_').split("_").join("_")
  end

  def self.file_ident
   (0...12).map { (65 + rand(26)).chr }.join
  end

  def self.today
  	Time.now.strftime("%d-%m-%y")
  end
end
