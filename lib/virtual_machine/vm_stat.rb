module VmStat
  def vm_stats
    return get("/virtual_machines/#{@virtual_machine['id']}/vm_stats")
  end

  def vm_stats_waiter
    puts "Whaiting for start generating new statistics."
    while Time.now.min != 0 do
      sleep 15
    end
    puts "Whaiting while new statistics will be generated."
    # TODO Get new stat as soon as appears.
    sleep 240
    return 0
  end

  def vs_hstats
    vm_stats_waiter
    stats = vm_stats
    hstats = {}

    hstats = {:disk_cost => disks_cost(stats),
             :ip_address_cost => ip_address_cost(stats),
             :rate_cost => rate_cost(stats),
             :template_cost => template_cost(stats),
             :total_cost => total_cost(stats),
             :vm_resources_cost => vm_resources_cost(stats),
             :usage_cost => usage_cost(stats)
    }

    puts "Disk cost - #{hstats[:disks_cost]}"
    Log.info("Disk cost - #{hstats[:disks_cost]}")
    puts "IP address cost - #{hstats[:ip_address_cost]}"
    Log.info("IP address cost - #{hstats[:ip_address_cost]}")
    puts "Rate cost - #{hstats[:rate_cost]}"
    Log.info("Rate cost - #{hstats[:rate_cost]}")
    puts "Template cost = #{hstats[:template_cost]}"
    Log.info("Template cost = #{hstats[:template_cost]}")
    puts "Total cost - #{hstats[:total_cost]}"
    Log.info("Total cost - #{hstats[:total_cost]}")
    puts "VS resources cost - #{hstats[:vm_resources_cost]}"
    Log.info("VS resources cost - #{hstats[:vm_resources_cost]}")
    puts "Usage cost - #{hstats[:usage_cost]}"
    Log.info("Usage cost - #{hstats[:usage_cost]}")
    return hstats
  end

  def price_for_last_hour
    return vs_hstats
  end

  private
  ######################################################################################################################
  # DISK
  ######################################################################################################################
  def disks_size_cost(stats)
    cost = 0
    stats.last['vm_hourly_stat']['billing_stats']['disks'].each do |disk|
      disk['costs'].each {|elem| cost += elem['cost'] if elem['resource_name'] == 'disk_size'}
    end
    return cost
  end

  def data_read_cost(stats)
    cost = 0
    stats.last['vm_hourly_stat']['billing_stats']['disks'].each do |disk|
      disk['costs'].each {|elem| cost += elem['cost'] if elem['resource_name'] == 'data_read'}
    end
    return cost
  end

  def data_written_cost(stats)
    cost = 0
    stats.last['vm_hourly_stat']['billing_stats']['disks'].each do |disk|
      disk['costs'].each {|elem| cost += elem['cost'] if elem['resource_name'] == 'data_written'}
    end
    return cost
  end

  def reads_completed(stats)
    cost = 0
    stats.last['vm_hourly_stat']['billing_stats']['disks'].each do |disk|
      disk['costs'].each {|elem| cost += elem['cost'] if elem['resource_name'] == 'reads_completed'}
    end
    return cost
  end

  def writes_completed_cost(stats)
    cost = 0
    stats.last['vm_hourly_stat']['billing_stats']['disks'].each do |disk|
      disk['costs'].each {|elem| cost += elem['cost'] if elem['resource_name'] == 'writes_completed'}
    end
    return cost
  end

  ######################################################################################################################
  # Network
  ######################################################################################################################
  def ip_address_cost(stats)
    cost = 0
    stats.last['vm_hourly_stat']['billing_stats']['network_interfaces'].each do |nic|
      nic['costs'].each {|elem| cost = elem['cost'] if elem['resource_name'] == 'ip_addresses'}
    end
    return cost
  end

  def rate_cost(stats)
    cost = 0
    stats.last['vm_hourly_stat']['billing_stats']['network_interfaces'].each do |nic|
      nic['costs'].each {|elem| cost = elem['cost'] if elem['resource_name'] == 'rate'}
    end
    return cost
  end

  def data_received_cost(stats)
    cost = 0
    stats.last['vm_hourly_stat']['billing_stats']['network_interfaces'].each do |nic|
      nic['costs'].each {|elem| cost = elem['cost'] if elem['resource_name'] == 'data_received'}
    end
    return cost
  end

  def data_sent_cost(stats)
    cost = 0
    stats.last['vm_hourly_stat']['billing_stats']['network_interfaces'].each do |nic|
      nic['costs'].each {|elem| cost = elem['cost'] if elem['resource_name'] == 'data_sent'}
    end
    return cost
  end

  ######################################################################################################################
  # Virtual Server
  ######################################################################################################################
  def template_cost(stats)
    cost = 0
    stats.last['vm_hourly_stat']['billing_stats']['virtual_machines'].each do |vm|
      vm['costs'].each {|elem| cost = elem['cost'] if elem['resource_name'] == 'template'}
    end
    return cost
  end

  def cpu_usage_cost(stats)
    cost = 0
    stats.last['vm_hourly_stat']['billing_stats']['virtual_machines'].each do |vm|
      vm['costs'].each {|elem| cost = elem['cost'] if elem['resource_name'] == 'cpu_usage'}
    end
    return cost
  end

  def total_cost(stats)
    return stats.last['vm_hourly_stat']['total_cost']
  end

  def vm_resources_cost(stats)
    stats.last['vm_hourly_stat']['vm_resources_cost']
  end

  def usage_cost(stats)
    stats.last['vm_hourly_stat']['usage_cost']
  end
end

