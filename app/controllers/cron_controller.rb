class CronController < ApplicationController
  before_filter :authenticate_user!
  include CronHelper

  def index
    @runs = Run.all
    @periods = %w(1.minute 10.minutes 30.minutes 1.hour 2.hours 3.hours 1.day 2.days 3.days)
    @statuses = %w(Inactive Active)
  end

  def reset
    system '>./config/schedule.rb;whenever -i'
    Run.update_all("cron_status = 'Inactive'")
    redirect_to cron_index_path
  end

  def update
    Run.update_cron_period_and_status(params[:runs])
    gen_whenever_file(params[:runs])
    system 'whenever -i'
    redirect_to cron_index_path
  end
end
