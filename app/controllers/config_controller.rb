class ConfigController < ApplicationController
  before_filter :authenticate_user!

  def update
    File.open('config/conf.yml', 'w') do |f|
      f.write(params[:conf].to_yaml)
    end
    redirect_to root_path
  end

  def edit
    file = 'config/conf.yml'
    begin
      @data = YAML.load_file(file) || YAML.load_file(file + '.example')
    rescue Errno::ENOENT
      system '>' + file
    end
    redirect_to(root_path, flash: { error: 'No config data for edit' }) unless @data
  end
end