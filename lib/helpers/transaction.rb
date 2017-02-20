require_relative 'waiter'

module Transaction
  include Waiter

  def wait_for_transaction(parent_id, parent_type, action)
    define_last_transaction_id
    Log.info("Waiting for #{parent_type} (#{parent_id}) transaction: #{action}")
    transaction = appeared_transaction(parent_id, parent_type, action)
    interface.last_transaction_id = transaction['id']
    transaction_completing(transaction)
  end

  def define_last_transaction_id
    interface.last_transaction_id
  rescue NoMethodError
    interface.class_eval{attr_accessor :last_transaction_id}
    interface.last_transaction_id ||= 0
  end

  private

  def appeared_transaction(parent_id, parent_type, action)
    wait_until(360, 5) do
      transactions = transaction_list.select do |t|
        t['parent_id'] == parent_id && t['parent_type'] == parent_type && t['action'] == action &&
            t['id'] > interface.last_transaction_id
      end
      return transactions.first if transactions.any?
    end
    Log.error("Unable to find transaction according to credentials, with parent id = #{parent_id}, parent_type#{parent_type} and action #{action}")
  end

  def transaction_list
    interface.get("/transactions", {page: 1, per_page: 1000}).map(&:transaction)
  end

  def transaction_status(transaction)
    wait_until(10800, 10) do
      status = get_status(transaction)
      return status if  status != 'running' && status != 'pending'
    end
  end

  def get_status(transaction)
    interface.get("/transactions/#{transaction['id']}")['transaction']['status']
  end

  def transaction_completing(transaction)
    log_text = "Transaction #{@url}/transactions/#{transaction['id']}.json"
    status = transaction_status(transaction)
    Log.error("#{log_text} FAILED") if  status == 'failed'
    Log.error("#{log_text} CANCELLED") if status == 'cancelled'
    true
  end
end