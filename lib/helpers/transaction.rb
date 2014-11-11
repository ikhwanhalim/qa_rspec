require 'helpers/onapp_http'
require 'yaml'

module Transaction
  include OnappHTTP
  def wait_for_transaction(parent_id, parent_type, action)
    data = YAML::load_file('config/conf.yml')
    @url = data['url']    
    @ip = data['ip']
    auth "#{@url}/users/sign_in", data['user'], data['pass']    
    i=1
    result = []
    $last_transaction_id = 0 if !defined?($last_transaction_id)        
    while result.empty? and i < 10 
      puts "looking for transaction on: #{@url}/transactions.json/page/#{i}/per_page/100"
      result = get("#{@url}/transactions.json/page/#{i}/per_page/100")    
      result = result.select {|transaction| transaction['transaction']['parent_id'] == parent_id and transaction['transaction']['parent_type'] == parent_type and transaction['transaction']['action'] == action}
      i += 1      
    end
    raise("Unable to find transaction according to credentials") if result.empty?    
    transaction = result.sort{|t| t['transaction']['id']}.last
    raise("Unable to find NEW transaction according to credentials") if transaction['transaction']['id'] <= $last_transaction_id
    $last_transaction_id = transaction['transaction']['id']
    transaction_id = transaction['transaction']['id']    
    loop do      
      sleep 10 
      transaction = get("#{@url}/transactions/#{transaction_id}.json")             
      break if transaction['transaction']['status'] == 'complete' || transaction['transaction']['status'] == 'failed' || transaction['transaction']['status'] == 'canceled' 
    end    
    raise("Transaction #{@url}/transactions/#{transaction_id}.json FAILED") if transaction['transaction']['status'] == 'failed'
    raise("Transaction #{@url}/transactions/#{transaction_id}.json CANCELED") if transaction['transaction']['status'] == 'canceled'
    true
  end
  
  
end
  


# db_cp.mysql("select id from transactions where parent_id = #{id} and parent_type = '#{parent_type}' and action = '#{action}' and id > '#{$last_transaction_id}' ORDER BY id DESC LIMIT 1;")