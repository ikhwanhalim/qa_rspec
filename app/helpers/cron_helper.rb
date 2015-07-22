module CronHelper
  def gen_whenever_file(runs)
    File.open('./config/schedule.rb', 'w') do |file|
      runs.select! { |r| r[:status] == 'Active' }
      file.write("set :output, './log/cron.log'\n")
      runs.each do |r|
        command = "Run.run_all_threads([#{r[:id]}])"
        file.write("every #{r[:period]} do; runner \"#{command}\"; end\n")
      end
    end
  end
end
