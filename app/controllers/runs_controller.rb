class RunsController < ApplicationController

  before_filter :authenticate_user!

  def index
    @runs = Run.all
    @templates = Template.env_list
    Template.new.set_undefined(@templates)
  end

  def new
    @run = Run.new
    @virt = %w{xen3 xen4 kvm5 kvm6}
    @files = Array[Run.directory_hash("tests")]
    @templates = Template.env_list
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

  def edit
    @run = Run.find(params[:id])
    @virt = %w{xen3 xen4 kvm5 kvm6}
    @files = Array[Run.directory_hash("tests")]
    @templates = Template.env_list
    @selected_templates = @templates.where(manager_id: YAML.load(@run.templates))
  end

  def update
    Report.where(run_id: params[:id]).delete_all
    array = []
    keys = ["template_name", "virt", "spec_files"]
    params[:run][:templates] ||= ["NoTemplatesSelected"]
    params[:run][:virt] ||= ["NoVirtualization"]
    @run = Run.find(params[:id])
    @run.update_attributes(params[:run])
    if @run.valid?
      reports = (@run.templates).product(@run.virt)
      reports.each do |report|
        hash = Hash[[keys,report + [@run.files.to_yaml]].transpose]
        array << Report.new(hash)
      end
      @run.reports += array
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
    if params[:manager_ids]
      Template.new.download_templates params[:manager_ids]
      redirect_to root_path
    else
      redirect_to(root_path, :flash => { :warning => "nothing to do!" })
    end
  end

  def run_all
    if !params[:runs]
      redirect_to(root_path, :flash => { :warning => "nothing to do!" })
    elsif templates_not_exists?(params[:runs])
      redirect_to(root_path, :flash => { :warning => "templates have not been downloaded yet!" })
    elsif is_testing_running?(params[:runs])
      redirect_to(root_path, :flash => { :warning => "some tests are running!" })
    else
      Run.run_all_threads(params[:runs])
      redirect_to root_path
    end
  end

  def kill
    Run.ready_and_running_report.each {|r| r.update_attribute(:status, "Stopped")}
    system "kill -9 `ps -ef | grep rspec | grep -v grep | awk '{print $2}'`"
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

  private

  def templates_not_exists?(run_ids)
    statuses = []
    run_ids.map do |id|
      run = Run.find id
      statuses += Template.env_list.where(manager_id: YAML.load(run.templates)).map &:status
    end
    statuses.include?('Undefined')
  end

  def is_testing_running?(run_ids)
    statuses = []
    run_ids.map do |id|
      run = Run.find id
      statuses += run.reports.map &:status
    end
    statuses.include?('Running')
  end
end