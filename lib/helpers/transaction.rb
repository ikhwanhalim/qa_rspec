require 'helpers/onapp_http'
require 'helpers/onapp_log'
require 'yaml'

module Transaction
  include OnappHTTP
  def wait_for_transaction(parent_id, parent_type, action)
    Log.info("Waiting for #{parent_type} (#{parent_id}) transaction: #{action}")
    auth unless self.conn
    result = []
    @last_transaction_id = 0 if !defined?(@last_transaction_id)
    10.times do
      result = get("/transactions", {page: 1, per_page: 1000})
      result.select! do |t|
          t['transaction']['parent_id'] == parent_id &&
            t['transaction']['parent_type'] == parent_type &&
            t['transaction']['action'] == action &&
            t['transaction']['id'] > @last_transaction_id
      end
      break if result.any?
      sleep 5
    end
    Log.error("Unable to find transaction according to credentials") if result.empty?
    transaction = result.last     
    @last_transaction_id = transaction['transaction']['id']
    transaction_id = transaction['transaction']['id']    
    loop do      
      sleep 10 
      status = get("/transactions/#{transaction_id}")['transaction']['status']
      break if status != 'running' || status != 'pending'
    end
    last_transaction_status = transaction['transaction']['status']
    log_text = "Transaction #{@url}/transactions/#{transaction_id}.json"
    Log.error("#{log_text} FAILED") if last_transaction_status == 'failed'
    Log.error("#{log_text} CANCELLED") if last_transaction_status == 'cancelled'
    true
  end
end