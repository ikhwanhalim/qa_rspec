class Run < ActiveRecord::Base
  attr_accessible :files, :templates, :title, :virt, :threads
  has_many :reports, dependent: :destroy
  validates :title, :files, :threads, presence: true

  class << self
    def ready_and_running_report
      Report.where("status = 'Ready' OR status = 'Running'")
    end

    def thread(report)
      template = Template.env_list(report.template_name).first
      manager_id = template ? template.manager_id : ""
      files = YAML.load(report.spec_files)
      report.report_file ||= Report.file_ident
      report.save
      full_report_path = "reports/#{report.report_file}"
      str_run = "LOG_FILE='#{report.report_file}' "\
                "VIRT_TYPE='#{report.virt}' "\
                "TEMPLATE_MANAGER_ID='#{manager_id}' "\
                "rspec #{files.join ' '} --format h --out #{full_report_path}"
      Log.info(str_run)
      Spawnling.new do
        report_by_id = Report.find(report.id)
        report_by_id.update_attribute(:status, "Running") if report_by_id.status != 'Stopped'
        system str_run
        report_by_id.update_attribute(:status, "Finished") if Report.find(report.id).status != 'Stopped'
      end
    end

    def run_all_threads(run_ids, root_url)
      hash = Hash[*run_ids.to_a.map {|k| [k, nil]}.flatten]
      hash.each do |k,v|
        hash[k] = Report.where(run_id: k)
        hash[k].each { |report| report.update_attribute(:status, "Ready") }
        hash[k].map!(&:id)
      end
      hash.each do |run,reports|
        Spawnling.new do
          start = Time.current
          run = Run.find(run)
          while reports.any?
            report = Report.find(reports.first)
            if report.status != 'Stopped'
              active_threads = Report.where("status='Running' and run_id='#{run.id}'")
              if active_threads.count < run.threads
                self.thread(report)
                reports.shift
              end
            else
              break
            end
            sleep 5
          end
          finish = Time.current
          message = "#{run.title} time #{(finish - start).round(2)} sec (<a href='#{root_url + run.base_uri}'>open</a>)"
          if run.reports.detect &:failed?
            hipchat_notify(message, :fail)
          else
            hipchat_notify(message, :success)
          end
        end
      end
    end

    def hipchat_notify(message, status)
      conf = Hashie::Mash.new(YAML.load_file('config/conf.yml'))
      client = HipChat::Client.new(conf.hipchat.token, api_version: 'v2')
      if status == :fail
        client[conf.hipchat.room].send('', message, color: 'red')
      elsif status == :success
        client[conf.hipchat.room].send('', message, color: 'green')
      end
    end

    def directory_hash(path, name=nil)
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

    def render_hash(hash, selected=[], html=nil)
      html ||= ''
      hash.sort_by! {|e| e.kind_of?(String) ? 1 : 0}
      hash.each do |h|
        if h.kind_of? String
          html << generate_select_boxes(h, selected)
          next
        end
        html << "<div class='arrow-right'></div>"
        html << "<label class='folder'>#{h[:data].upcase}</label><ul>"
        if h[:children].detect { |c| c.kind_of? Hash }
          render_hash(h[:children], selected, html)
        else
          h[:children].to_a.each do |c|
            html << generate_select_boxes(c, selected)
          end
        end
        html << "</ul><br>"
      end
      html
    end

    def generate_select_boxes(el, selected)
      cb = if selected.include?(el)
             "<input class='checkbox' type='checkbox' name='run[files][]' value='#{el}' checked>"
           else
             "<input class='checkbox' type='checkbox' name='run[files][]' value='#{el}'>"
           end
      return "<li>#{cb}<label>#{el.split('/').last}</label></li>"
    end

    def update_cron_period_and_status(runs)
      Run.transaction do
        runs.each do |r|
          record = Run.find(r[:id])
          record.cron_period = r[:period]
          record.cron_status = r[:status]
          record.save
        end
      end
    end
  end

  def base_uri
    runs_report_path(id: id)
  end
end
