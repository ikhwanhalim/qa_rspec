require 'helpers/onapp_http'
require 'yaml'

module Transaction
  include OnappHTTP
  def wait_for_transaction(parent_id, parent_type, action)
    puts "Waiting for #{parent_type} (#{parent_id}) transaction: #{action}"
    auth unless self.conn
    i=1
    result = []
    $last_transaction_id = 0 if !defined?($last_transaction_id)        
    while result.empty? && i < 10
      result = get("/transactions", {page: i, per_page: 100})
      result = result.select do |t|
          t['transaction']['parent_id'] == parent_id &&
            t['transaction']['parent_type'] == parent_type &&
            t['transaction']['action'] == action
      end
      i += 1      
    end
    raise("Unable to find transaction according to credentials") if result.empty?
    result = result.select {|t| t['transaction']['id'] > $last_transaction_id }    
    raise("Unable to find NEW transaction according to credentials") if result.empty?
    transaction = result.last     
    $last_transaction_id = transaction['transaction']['id']
    transaction_id = transaction['transaction']['id']    
    loop do      
      sleep 10 
      transaction = get("/transactions/#{transaction_id}")
      break if transaction['transaction']['status'] == 'complete' ||
        transaction['transaction']['status'] == 'failed' ||
        transaction['transaction']['status'] == 'canceled'
    end    
    raise("Transaction #{@url}/transactions/#{transaction_id}.json FAILED") if transaction['transaction']['status'] == 'failed'
    raise("Transaction #{@url}/transactions/#{transaction_id}.json CANCELED") if transaction['transaction']['status'] == 'canceled'
    true
  end
  
  
end
  


# db_cp.mysql("select id from transactions where parent_id = #{id} and parent_type = '#{parent_type}' and action = '#{action}' and id > '#{$last_transaction_id}' ORDER BY id DESC LIMIT 1;")