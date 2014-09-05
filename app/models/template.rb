class Template < ActiveRecord::Base
  attr_accessible :template_name, :template_url
  @agent = Mechanize.new

  def self.update
    templates = Template.all.map {|t| t.template_name}
    keys = ["template_name", "template_url"]
    linux_array = []
    freebsd_array = []
    freebsd_link = 'http://templates.repo.onapp.com/FreeBSD/'
    linux_link = 'http://templates.repo.onapp.com/Linux/'
    freebsd_urls = @agent.get(freebsd_link).links.drop(5).map {|t| t.href}
    linux_urls = @agent.get(linux_link).links.drop(5).map {|t| t.href}
    
    linux_urls.each do |template|
      unless templates.include?(template)
        hash = Hash[[keys,["#{template}", "#{linux_link + template}"]].transpose]
        linux_array << Template.new(hash)
      end
    end

    freebsd_urls.each do |template|
      unless templates.include?(template)
        hash = Hash[[keys,["#{template}", "#{freebsd_link + template}"]].transpose]
        freebsd_array << Template.new(hash)
      end
    end

    Template.transaction do
      Template.import freebsd_array + linux_array
    end
  end
end
