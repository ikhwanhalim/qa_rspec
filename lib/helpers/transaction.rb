require 'helpers/onapp_http'
require 'helpers/onapp_log'
require 'yaml'

module Transaction
  include OnappHTTP
  def wait_for_transaction(parent_id, parent_type, action)
    Log.info("Waiting for #{parent_type} (#{parent_id}) transaction: #{action}")
    auth unless self.conn
    result = []
    $last_transaction_id = 0 if !defined?($last_transaction_id)        
    10.times do
      result = get("/transactions", {page: 1, per_page: 1000})
      result = result.select do |t|
          t['transaction']['parent_id'] == parent_id &&
            t['transaction']['parent_type'] == parent_type &&
            t['transaction']['action'] == action
      end
      break if result.any?
      sleep 5
    end
    Log.error("Unable to find transaction according to credentials") if result.empty?
    result = result.select {|t| t['transaction']['id'] > $last_transaction_id }    
    Log.error("Unable to find NEW transaction according to credentials") if result.empty?
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
    if transaction['transaction']['status'] == 'failed'
      Log.error("Transaction #{@url}/transactions/#{transaction_id}.json FAILED")
    elsif transaction['transaction']['status'] == 'canceled'
      Log.error("Transaction #{@url}/transactions/#{transaction_id}.json CANCELED")
    end
    true
  end
  
  
end
  


# db_cp.mysql("select id from transactions where parent_id = #{id} and parent_type = '#{parent_type}' and action = '#{action}' and id > '#{$last_transaction_id}' ORDER BY id DESC LIMIT 1;")