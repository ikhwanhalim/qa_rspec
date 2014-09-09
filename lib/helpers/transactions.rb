class Transaction
  class << self
    def wait (id, parent_type, action)
      # sleep added for slow databases
      sleep 2
      result = $db_cp.mysql("select id from transactions where parent_id = #{id} and parent_type = '#{parent_type}' and action = '#{action}' and id > '#{$last_transaction_id}' ORDER BY id DESC LIMIT 1;")
      if result
        sql_str = result.split("\n")
        sql_str.pop
        sql_str.shift
        transaction_id = sql_str.first
        unless transaction_id.nil?
          $last_transaction_id = transaction_id
          puts "Transaction ID = #{transaction_id}"
        else
          p "Failed to locate for #{parent_type} #{id}, #{action}"
          raise ("Failed to locate for #{parent_type} #{id}, #{action}")
          return false
        end
      else
        puts "Cant select transaction id for #{parent_type} #{id}, #{action}  - #{result}"
        raise ("Cant select transaction id for #{parent_type} #{id}, #{action}  - #{result}")
      end
      status = 'pending'
      while status == 'running' || status == 'pending'
        result = $db_cp.mysql("select status from transactions where id = #{transaction_id};")
        if result
          sql_str = result.split("\n")
          sql_str.pop
          sql_str.shift
          status = sql_str.first
          unless status.nil?

          else
            p 'Got Nil status'
            raise ('Got Nil status')
          end
        else
          puts "Cant select transaction with transaction ID = #{transaction_id}"
          raise ("Cant select transaction with transaction ID = #{transaction_id}")
        end
        case status
          when 'complete'
            p "Waiting #{parent_type} ID #{id}  #{action}. Current status : #{status}"
            return true
          when 'running'
            p "Waiting #{parent_type} ID #{id}  #{action}. Current status : #{status}"
            sleep 5
          when 'pending'
            p "Waiting #{parent_type} ID #{id}  #{action}. Current status : #{status}"
            sleep 5
          when 'failed'
            p "Transaction #{parent_type} #{action} - #{status}"
            raise ("Transaction #{parent_type} #{action} - #{status} \n http://#{$cp.ip}/logs/")
          when 'cancelled'
            p "Transaction #{parent_type} #{action} - #{status}"
            raise ("Transaction #{parent_type} #{action} - #{status}")
          else
            p "Transaction #{parent_type} #{action} - Unknown status #{status}"
            raise ("Transaction #{parent_type} #{action} - Unknown status #{status}")
        end
      end

    end
  end
end