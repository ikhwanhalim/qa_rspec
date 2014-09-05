class RunsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @runs = Run.all
  end

  def new
    @run = Run.new
    @virt = ["xen3", "xen4", "kvm5", "kvm6"]
    @files = Dir.glob File.join("tests", "**", "*.rb")
    @templates = Template.find(:all, :order => :template_name)
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
    Template.update
    redirect_to root_path
  end

  def run_all
    runs = params[:runs]
    runs.each do |r|
      run = Run.find(r)
      reports = run.reports
      reports.map { |report| report.update_attribute(:status, "Ready") }
      Spawnling.new do
        while reports.any? and reports.first.status != 'Stopped'
          active_runs = Report.where("status='Running' and run_id='#{run.id}'")
          if active_runs.count < run.threads and reports.any?
            Run.thread(run.server, reports.first)
            reports.shift
          end
          sleep 10
        end
      end
    end
    redirect_to root_path
  end

  def report
    @directory = 'reports/' + Report.today
    Dir.mkdir @directory if !File.directory?(@directory)
    @reports = Run.find(params[:id]).reports
  end

  def destroy
    Run.find(params[:id]).destroy
    redirect_to root_path
  end
end
