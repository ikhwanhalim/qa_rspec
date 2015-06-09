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
    stats = vm_stats
    #vm_resources_cost = 0
    #if stats != nil
    #  vm_resources_cost = stats.last['vm_hourly_stat']['vm_resources_cost']
    #end
    puts "Disk cost - #{disks_cost}"
    puts "IP address cost - #{ip_address_cost}"
    puts "Rate cost - #{rate_cost}"
    puts "Template cost = #{template_cost}"
    puts "Total cost - #{total_cost}"
    puts "VS resources cost - #{vm_resources_cost}"
    puts "Usage cost - #{usage_cost}"
    return 0
  end

  def price_for_last_hour
    return vm_stats_waiter
  end

  private
  def disks_cost
    total = 0
    stats.last['vm_hourly_stat']['billing_stats']['disks'].each do |disk|
      total += disk['costs'].first['cost']
    end
    return total
  end

  def ip_address_cost
    stats.last['vm_hourly_stat']['billing_stats']['network_interfaces'].each do |nic|
      nic['costs'].each {|elem| ip_cost = elem['cost'] if elem['resource_name' == 'ip_addresses']}
    end
    return ip_cost
  end

  def rate_cost
    stats.last['vm_hourly_stat']['billing_stats']['network_interfaces'].each do |nic|
      nic['costs'].each {|elem| rate_cost = elem['cost'] if elem['resource_name' == 'rate']}
    end
    return rate_cost
  end

  def template_cost
    stats.last['vm_hourly_stat']['billing_stats']['virtual_machines'].each do |vm|
      vm['costs'].each {|elem| template_cost = elem['cost'] if elem['resource_name' == 'template']}
    end
    return template_cost
  end

  def total_cost
    return stats.last['vm_hourly_stat']['total_cost']
  end

  def vm_resources_cost
    stats.last['vm_hourly_stat']['vm_resources_cost']
  end

  def usage_cost
    stats.last['vm_hourly_stat']['usage_cost']
  end
end

