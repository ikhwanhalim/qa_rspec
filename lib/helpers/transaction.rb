module Transaction
  def wait_for_transaction(parent_id, parent_type, action)
    Log.info("Waiting for #{parent_type} (#{parent_id}) transaction: #{action}")
    begin
      interface.last_transaction_id
    rescue NoMethodError
      interface.class_eval{attr_accessor :last_transaction_id}
    end
    result = []
    interface.last_transaction_id ||= 0
    60.times do
      result = interface.get("/transactions", {page: 1, per_page: 1000})
      result.select! do |t|
          t['transaction']['parent_id'] == parent_id &&
            t['transaction']['parent_type'] == parent_type &&
            t['transaction']['action'] == action &&
            t['transaction']['id'] > interface.last_transaction_id
      end
      break if result.any?
      sleep 5
    end
    Log.error("Unable to find transaction according to credentials") if result.empty?
    transaction = result.last
    interface.last_transaction_id = transaction_id = transaction['transaction']['id']
    loop do
      sleep 10 
      status = interface.get("/transactions/#{transaction_id}")['transaction']['status']
      break if status != 'running' && status != 'pending'
    end
    last_transaction_status = interface.get("/transactions/#{transaction_id}")['transaction']['status']
    log_text = "Transaction #{@url}/transactions/#{transaction_id}.json"
    Log.error("#{log_text} FAILED") if last_transaction_status == 'failed'
    Log.error("#{log_text} CANCELLED") if last_transaction_status == 'cancelled'
    true
  end
end