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
    stats = vm_stats
    hstats = {}

    hstats = {:disks_size_cost => disks_size_cost(stats),
              :data_read_cost => data_read_cost(stats),
              :data_written_cost => data_written_cost(stats),
              :reads_completed_cost => reads_completed_cost(stats),
              :writes_completed_cost => writes_completed_cost(stats),
              :ip_address_cost => ip_address_cost(stats),
              :rate_cost => rate_cost(stats),
              :data_received_cost => data_received_cost(stats),
              :data_sent_cost => data_sent_cost(stats),
              :cpu_shares_cost => cpu_shares_cost(stats),
              :cpus_cost => cpus_cost(stats),
              :memory_cost => memory_cost(stats),
              :template_cost => template_cost(stats),
              :cpu_usage_cost => cpu_usage_cost(stats),
              :total_cost => total_cost(stats),
              :vm_resources_cost => vm_resources_cost(stats),
              :usage_cost => usage_cost(stats)
    }

    hstats.keys.each do |key|
      puts "#{key.to_s.capitalize.sub! '_', ' '} - #{hstats[key]}"
      Log.info("#{key.to_s.capitalize.sub! '_', ' '} - #{hstats[key]}")
    end
    return hstats
  end

  def price_for_last_hour
    return vs_hstats
  end

  private
  # Helpers
  def disk_resources_cost(stats, resource_name)
    cost = 0
    stats.last['vm_hourly_stat']['billing_stats']['disks'].each do |disk|
      disk['costs'].each {|elem| cost += elem['cost'] if elem['resource_name'] == resource_name}
    end
    return cost
  end

  def network_resources_cost(stats, resource_name)
    cost = 0
    stats.last['vm_hourly_stat']['billing_stats']['network_interfaces'].each do |nic|
      nic['costs'].each {|elem| cost = elem['cost'] if elem['resource_name'] == resource_name}
    end
    return cost
  end

  def virtual_machine_resources_cost(stats, resource_name)
    cost = 0
    stats.last['vm_hourly_stat']['billing_stats']['virtual_machines'].each do |vm|
      vm['costs'].each {|elem| cost = elem['cost'] if elem['resource_name'] == resource_name}
    end
    return cost
  end
  ######################################################################################################################
  # DISK
  ######################################################################################################################
  def disks_size_cost(stats)
    return disk_resources_cost(stats, 'disk_size')
  end

  def data_read_cost(stats)
    return disk_resources_cost(stats, 'data_read')
  end

  def data_written_cost(stats)
    return disk_resources_cost(stats, 'data_written')
  end

  def reads_completed_cost(stats)
    return disk_resources_cost(stats, 'reads_completed')
  end

  def writes_completed_cost(stats)
    return disk_resources_cost(stats, 'writes_completed')
  end

  ######################################################################################################################
  # Network
  ######################################################################################################################
  def ip_address_cost(stats)
    return network_resources_cost(stats, 'ip_addresses')
  end

  def rate_cost(stats)
    return network_resources_cost(stats, 'rate')
  end

  def data_received_cost(stats)
    return network_resources_cost(stats, 'data_received')
  end

  def data_sent_cost(stats)
    return network_resources_cost(stats, 'data_sent')
  end

  ######################################################################################################################
  # Virtual Server
  ######################################################################################################################
  def cpu_shares_cost(stats)
    return virtual_machine_resources_cost(stats, 'cpu_shares')
  end

  def cpus_cost(stats)
    return virtual_machine_resources_cost(stats, 'cpus')
  end

  def memory_cost(stats)
    return virtual_machine_resources_cost(stats, 'memory')
  end

  def template_cost(stats)
    return virtual_machine_resources_cost(stats, 'template')
  end

  def cpu_usage_cost(stats)
    return virtual_machine_resources_cost(stats, 'cpu_usage')
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

