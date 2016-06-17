require_relative 'transaction'

module BackupOperationsWaiters
  include Transaction

  def method_missing name
    if name.to_s.include?('wait_for')
      self.class.class_eval do
        define_method(name) do
          wait_for_transaction(id, 'Backup', name.to_s.gsub('wait_for_', ''))
        end
      end
    end
    send(name)
  end
end