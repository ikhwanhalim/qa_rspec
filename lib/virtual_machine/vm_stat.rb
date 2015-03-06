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
    vm_resources_cost = 0
    if stats != nil
      vm_resources_cost = stats.last['vm_hourly_stat']['vm_resources_cost']
    end
    return vm_resources_cost
  end

  def price_for_last_hour
    return vm_stats_waiter
  end
end