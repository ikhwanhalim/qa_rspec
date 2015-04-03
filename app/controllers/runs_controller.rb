class RunsController < ApplicationController

  before_filter :authenticate_user!

  def index
    @runs = Run.all
  end

  def new
    @run = Run.new
    @virt = %w{xen3 xen4 kvm5 kvm6}
    @files = Array[Run.directory_hash("tests")]
    @templates = Template.all.sort_by {|t| t.label}
  end
 
  def create
    array = []
    keys = ["template_name", "virt", "spec_files"]
    params[:run][:templates] ||= ["NoTemplatesSelected"]
    params[:run][:virt] ||= ["NoVirtualization"]
    @run = Run.new(params[:run])
    if @run.valid?
      reports = (@run.templates).product(@run.virt)
      reports.each do |report|
        hash = Hash[[keys,report + [@run.files.to_yaml]].transpose]
        array << Report.new(hash)
      end
      @run.reports += array
      @run.save
      redirect_to root_path
    else
      errors = @run.errors.messages
      errors.each {|k,v| errors[k]=v.first}
      redirect_to new_run_path, flash: errors
    end
  end

  def update_templates
    Template.new.update_templates
    redirect_to root_path
  end

  def download_templates
    Template.new.download_templates params[:manager_ids]
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
              Run.thread(report)
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
    @directory = Rails.root + 'reports'
    @reports = Run.find(params[:id]).reports
  end

  def refresh_report
    @directory = Rails.root + 'reports'
    @reports = Run.find(params[:id]).reports
    render :partial => "runs/status"
  end

  def destroy
    Run.find(params[:id]).destroy
    redirect_to root_path
  end
end
