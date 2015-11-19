module Mysql
  def get_db_credentionals
    Log.info("Get mysql pass and database...")
    result = execute_with_keys(ip, 'root', "cat /onapp/interface/config/database.yml || echo error")
    Log.error(result) if result.include?('error')
    YAML.load(result)['production']
  end

  def query(query_string)
    db = get_db_credentionals
    command = "mysql --password='#{db['password']}' -h'#{db['host']}' #{db['database']} -e\"#{query_string}\" && echo done || echo error"
    result = execute_with_keys(ip, 'root', command)
    result.include?('done') ? true : Log.error(result)
  end
end