module Log
  extend self

  WARN = "\e[1;33m"
  ERR = "\e[1;31m"
  CLEAR = "\e[0m"


  def error(message)
    write formatted_message(message, "ERR")
    raise message
  end

  def warn(message)
    write formatted_message(message, "WARN")
  end

  def info(message)
    write formatted_message(message, "INFO")
  end

  private

  def write(formatted_message)
    log_file = ENV['LOG_FILE'] || 'autotests'
    File.open("log/#{log_file}.log", "a") { |f| f << formatted_message }
  end

  def formatted_message(message, message_type)
    output = "#{Time.now} | #{message_type}: #{message}\n"
    puts output
    if message_type == "ERR"
      ERR + output + CLEAR
    elsif message_type == "WARN"
      WARN + output + CLEAR
    else
      output
    end
  end
end
