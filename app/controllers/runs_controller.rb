class RunsController < ApplicationController

  before_filter :authenticate_user!

  def index
    @runs = Run.all
  end

  def new
    @run = Run.new
    @virt = %w{xen3 xen4 kvm5 kvm6}
    @files = Array[Run.directory_hash("tests")]#Dir.glob File.join("tests", "**", "*.rb")
    @templates = Template.all.sort_by {|t| t.label}
  end
 
  def create
    array = []
    keys = ["template_name", "virt", "spec_files"]
    params[:run][:templates] = params[:templates]
    params[:run][:files] = params[:files]
    errors = Run.errors_handler(params[:run])
    if errors.first
      flash.merge! errors
      redirect_to new_run_path
    else
      @run = Run.new(params[:run])
      reports = @run.templates.product(@run.virt)
      reports.each do |report|
        hash = Hash[[keys,report + [@run.files.to_yaml]].transpose]
        array << Report.new(hash)
      end
      @run.reports += array
      @run.save
      redirect_to root_path
    end
  end

  def update_templates
    Template.new.update
    redirect_to root_path
  end

  def run_all
    $hash = Hash[*params[:runs].map {|k| [k, nil]}.flatten]
    $hash.each do |k,v|
      $hash[k] = Report.where(run_id: k)
      $hash[k].each { |report| report.update_attribute(:status, "Ready") }
      $hash[k].map!(&:id)
    end
    $hash.each do |run,reports|
      Spawnling.new do
        run = Run.find(run)
        while reports.any?
          report = Report.find(reports.first)
          if report.status != 'Stopped'
            active_threads = Report.where("status='Running' and run_id='#{run.id}'")
            if active_threads.count < run.threads
              Run.thread(run.server, report)
              reports.shift
            end
          end
          sleep 5
        end
      end
    end
    redirect_to root_path
  end

  def kill
    $hash.each do |run_id, reports_ids|
      reports = Report.where("run_id = #{run_id} AND status != 'Finished'")
      reports.each {|r| r.update_attribute(:status, "Stopped")}
      $hash[run_id].clear
    end
    Spawnling.new do
      system "kill -9 `ps -ef | grep rspec | grep -v grep | awk '{print $2}'`"
    end
    redirect_to root_path
  end

  def report
    @directory = 'reports/' + Report.today
    Dir.mkdir @directory if !File.directory?(@directory)
    @reports = Run.find(params[:id]).reports
  end

  def refresh_report
    @directory = 'reports/' + Report.today + "/"
    Dir.mkdir @directory if !File.directory?(@directory)
    @reports = Run.find(params[:id]).reports
    @reports.each do |r|
      begin
        report_page = Nokogiri::HTML(open(@directory + r.report_file))
        r.update_attribute(:status, "Failed") if report_page.css(".failed").any?
      rescue
        r.update_attribute(:status, "Old")
      end
    end
    render :partial => "runs/status"
  end

  def destroy
    Run.find(params[:id]).destroy
    redirect_to root_path
  end
end
