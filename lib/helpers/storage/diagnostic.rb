require_relative 'storage_client'
module Diagnostic
  include StorageClient

  # VDISK DIAGNOSTIC FAILURES:
  # +No disks with partial memberlist found
  # -No disks with no stripe replicas found     # !!!!!doesn't work since 3.3
  # +No disks with no redundancy found
  # +No partially online disks found
  # +No disks in other degraded states found
  # +No partial nodes found
  # +No inactive nodes found
  # +No nodes with delayed ping found
  # +No nodes with high utilization found
  # +No out of space nodes found
  # +No inactive controllers found
  # +No unreferenced NBDs found
  # No reused NBDs found
  # +No dangling device mappers found          # as part of partially online vdisk
  # +No stale cache volumes
  # +No disks with inactive cache

  # storageAPI:

  def get_orphaned_cache_lvs
    API.is_get_cache_orphans(obtain_frontend_uuid)
  end

  # General:

  def make_online
    vdisks_list = ssh_execute(SshCommands::OnCloudbootHypervisor.get_vdisks_list)
    frontend_uuid = obtain_frontend_uuid
    ssh_execute(SshCommands::OnCloudbootHypervisor.online_vdisks(vdisks_list, frontend_uuid))
  end

  def make_vdisk_online(vdisk)
    ssh_execute(SshCommands::OnCloudbootHypervisor.online_vdisk(vdisk, obtain_frontend_uuid))
  end

  def obtain_bdev_conn
    ssh_execute(SshCommands::OnCloudbootHypervisor.get_bdev_connections)
  end

  def obtain_bdev_conn_vdisk(vdisk)
    ssh_execute(SshCommands::OnCloudbootHypervisor.get_bdev_connections_per_vdisk(vdisk))
  end

  def obtain_controller_ip
    (ssh_execute(SshCommands::OnCloudbootHypervisor.get_controller_ip)).join
  end

  def obtain_vdisk_members(vdisk)
    ssh_execute(SshCommands::OnCloudbootHypervisor.get_vdisk_members(vdisk)).join.split(" ")
  end

  def obtain_frontend_uuid
    ssh_execute(SshCommands::OnCloudbootHypervisor.get_frontend_uuid).join
  end

  def obtain_frontend_node_members
    ssh_execute(SshCommands::OnCloudbootHypervisor.get_frontend_node_members)
  end

  def obtain_common_local_members(vdisk)
    obtain_vdisk_members(vdisk) & obtain_frontend_node_members
  end

  def obtain_node_to_forget(vdisk)
    ssh_execute(SshCommands::OnCloudbootHypervisor.get_node(vdisk)).join.to_i
  end

  def forget_node(vdisk, node)
    ssh_execute(SshCommands::OnCloudbootHypervisor.forget_node(vdisk, node))
  end

  def get_partial_node_to_repair(vdisk)
    obtain_common_local_members(vdisk)[0]
  end

  def max_vdisk_size
    ssh_execute(SshCommands::OnCloudbootHypervisor.get_max_vdisk_size).join.to_s
  end

  def high_utilisation_vdisk_size
    (max_vdisk_size.to_i - 100).to_s
  end

  def rebalance_vdisk(vdisk_id)
    interface.post("/storage/#{@hypervisor_group}/data_stores/#{get_storage_datastore_id}/disks/#{vdisk_id}/repair",
                   {"rebalance" => "true",
                    "node_ids" => make_no_redundancy(vdisk_id),
                    "endpoint_id" => "#{@hypervisor_group}",
                    "storage_data_store_id" => "#{get_storage_datastore_id}",
                    "storage_disk_id" => "#{vdisk_id}"})
  end

  def repair_partial_node(node)
    interface.post("/storage/#{@hypervisor_group}/health_checks/repair/partial_nodes",
                   {"node_id" => node,
                    "endpoint_id" => "#{@hypervisor_group}",
                    "type" => "partial_nodes"})
  end

  def repair_unreferenced_nbds
    interface.post("/storage/#{@hypervisor_group}/health_checks/repair/unreferenced_nbds", {
        "endpoint_id" =>"#{@hypervisor_group}",
        "type" =>"unreferenced_nbds"
    })
  end

  def repair_stale_cache_volumes
    interface.post("/storage/#{@hypervisor_group}/health_checks/repair/stale_cache_volumes", {
        "endpoint_id" =>"#{@hypervisor_group}",
        "type" =>"stale_cache_volumes"
    })
  end

  def edit_is_datastore(autohealing=1, cache=0)
    if cache == 1
      interface.put("/settings/data_stores/#{get_settings_datastore_id}",
                    {"data_store" => {
                        "auto_healing" => "#{autohealing}",
                        "integrated_storage_cache_enabled" => "#{cache}",
                        "integrated_storage_cache_settings" =>
                            {"cache_mode" => "writethrough",
                             "cache_line_size" => "512",
                             "migration_threshold" => "128",
                             "cache_percentage" => "10"}
                    },
                     "id" => "#{get_settings_datastore_id}"})
    else
      interface.put("/settings/data_stores/#{get_settings_datastore_id}",
                    {"data_store" => {
                        "auto_healing" => "#{autohealing}",
                        "integrated_storage_cache_enabled" => "#{cache}"
                    },
                     "id" => "#{get_settings_datastore_id}"})
    end
  end

  def node_repaired?
    wait_until(360, 10) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.get_partial_nodes).join.to_i < 1
    end
  end

  def node_activated?
    ssh_execute(SshCommands::OnCloudbootHypervisor.make_active_node)
    wait_until(360, 10) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.get_inactive_nodes).join.to_i < 1
    end
  end

  def delayed_ping_nodes_repaired?
    ssh_execute(SshCommands::OnCloudbootHypervisor.repair_nodes_with_delayed_ping(obtain_controller_ip))
    wait_until(360, 10) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.get_delayed_ping_nodes).join.to_i < 1
    end
  end


  def high_utilisation_nodes_empty?
    wait_until(360, 10) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.get_utilisation_node).join.to_i < 1
    end
  end

  def inactive_controllers_repair?
    interface.post("/storage/#{@hypervisor_group}/health_checks/repair/inactive_controllers", {
        "hypervisor_id" => "#{@hypervisor_id}",
        "id" => "0",
        "endpoint_id" => "#{@hypervisor_group}",
        "type" => "inactive_controllers"
    })
    wait_until(360, 10) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.get_storage_controller).join.to_i >= 1
    end
  end

  # Diagnostic

  def make_degraded
    make_online
    list_bdev_conn = obtain_bdev_conn
    ssh_execute(SshCommands::OnCloudbootHypervisor.kill_one_nbd(list_bdev_conn))
    wait_until(360, 10) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.get_degraded_vdisks).join.to_i >= 1
    end
  end

  def make_vdisk_degraded(vdisk)
    make_vdisk_online(vdisk)
    list_bdev_conn = obtain_bdev_conn_vdisk(vdisk)
    ssh_execute(SshCommands::OnCloudbootHypervisor.kill_one_nbd(list_bdev_conn))
    wait_until(360, 10) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.get_degraded_vdisk(vdisk)).join.to_i >= 1
    end
  end

  def make_partial_memberlist(vdisk)
    make_online
    node = ssh_execute(SshCommands::OnCloudbootHypervisor.get_node(vdisk)).join.to_i
    ssh_execute(SshCommands::OnCloudbootHypervisor.forget_node(vdisk, node))
    wait_until(360, 10) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.get_partial_memberlist_vdisk).join.to_i >= 1
    end
  end

  def make_no_redundancy(vdisk)
    make_online
    frontend_node_members = obtain_frontend_node_members
    vdisk_members = obtain_vdisk_members(vdisk)
    common_members = obtain_common_local_members(vdisk)
    not_used_frontend_members = frontend_node_members - vdisk_members
    remote_frontend_membres = vdisk_members - frontend_node_members
    members_to_rebalance = common_members << not_used_frontend_members[0] && common_members << remote_frontend_membres[0]
    members_to_rebalance
  end

  def get_no_redundant_vdisk
    wait_until(360, 10) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.vdisk_with_no_redundancy).join.to_i >= 1
    end
  end

  def make_partially_online(vdisk)
    make_online
    list_bdev_conn = ssh_execute(SshCommands::OnCloudbootHypervisor.get_bdev_connections_per_vdisk(vdisk))
    ssh_execute(SshCommands::OnCloudbootHypervisor.kill_three_nbds(list_bdev_conn))
    wait_until(360, 10) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.get_partially_online_vdisks(vdisk)).join.to_i >= 1
    end
  end

  def make_other_degraded_state(vdisk)
    make_online
    common_members = obtain_common_local_members(vdisk)
    node_file = ssh_execute(SshCommands::OnCloudbootHypervisor.
        get_node_file(obtain_controller_ip, vdisk, common_members[0]))
    ssh_execute(SshCommands::OnCloudbootHypervisor.
        remove_node_file(obtain_controller_ip, node_file.join(",")))

    wait_until(360, 10) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.
          get_other_degraded_state_vdisk(vdisk)).join.to_i >= 1
    end
  end

  def make_partial_nodes
    ssh_execute(SshCommands::OnCloudbootHypervisor.
        make_partial_node(obtain_controller_ip))

    wait_until(360, 10) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.get_partial_nodes).join.to_i >= 1
    end
  end

  def make_inactive_nodes
    ssh_execute(SshCommands::OnCloudbootHypervisor.make_inactive_node)

    wait_until(360, 10) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.get_inactive_nodes).join.to_i >= 1
    end
  end

  def make_nodes_with_delayed_ping
    ssh_execute(SshCommands::OnCloudbootHypervisor.make_nodes_with_delayed_ping(obtain_controller_ip))

    wait_until(360, 10) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.get_delayed_ping_nodes).join.to_i >= 1
    end
  end

  def make_nodes_with_high_utilisation(vdisk)
    make_online
    wait_until(3600, 100) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.ddwrapper_vdisk_4096k(vdisk)).join.to_i == 0
    end
  end

  def get_nodes_with_high_utilisation
    wait_until(360, 10) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.get_utilisation_node).join.to_i >= 1
    end
  end

  def make_out_of_space_nodes(vdisk)
    make_online
    wait_until(9000, 100) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.ddwrapper_vdisk_4096k(vdisk)).join.to_i == 0
    end
  end

  def make_inactive_controllers
    ssh_execute(SshCommands::OnCloudbootHypervisor.destroy_controller)
    wait_until(360, 10) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.get_storage_controller).join.to_i < 1
    end
  end

  def make_unreferenced_nbds(vdisk)
    make_online
    wait_until(360, 10) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.remove_mapper_device(vdisk)).join.to_i == 0
    end
  end

  def make_reused_nbds(vdisk)
    make_online
    wait_until(360, 10) do
      ssh_execute(SshCommands::OnCloudbootHypervisor.remove_mapper_device(vdisk)).join.to_i == 0
    end
  end

  def make_stale_cache_volumes(vdisk)
    ssh_execute(SshCommands::OnCloudbootHypervisor.acquire_cache_vdisk(vdisk))
    ssh_execute(SshCommands::OnCloudbootHypervisor.online_cache_vdisk(vdisk, obtain_frontend_uuid))
    ssh_execute(SshCommands::OnCloudbootHypervisor.reboot_hv)
    wait_until(720, 360) do
      get_orphaned_cache_lvs["orphan_cache_lvs"] != []
    end
  end

  def make_inactive_cache(autohealing, cache)
    edit_is_datastore(autohealing, cache)
    wait_until(360, 10) do
      return true
    end
  end
end