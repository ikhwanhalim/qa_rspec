module SshCommands
  module OnVirtualServer
    extend self

    def update_os(operating_system_distro)
      if operating_system_distro == 'rhel'
        "yum update -y --nogpgcheck;echo $?"
      elsif operating_system_distro == 'ubuntu'
        "apt-get update;apt-get --allow-unauthenticated upgrade -y;echo $?"
      end
    end

    def disk_size(mount_point, swap = false)
      if swap
        "grep SwapTotal /proc/meminfo |awk '{print \\$2}'"
        #"swapon |tail -1 |awk '{print $3}' |sed 's/.$//'"
      else
        "df -k | grep '#{mount_point}$' | awk '{print \\$2}'"
      end
    end

    def mounted_disks
      "df -hm | awk -v dd=':' '/mnt/ {print $6dd$2}'"
    end

    def swap(system)
      if system == 'linux'
        "free -m | grep wap: | awk {'print $2-G-B-H'}"
      elsif system == 'freebsd'
        "swapinfo -hm | awk '/dev/ {print $2}'"
      end
    end

    def cpus(system)
      if system == 'linux'
        "cat /proc/cpuinfo |grep processor |tail -1 |awk '{print $3+1}'"
      elsif system == 'freebsd'
        "dmesg | grep -oE 'cpu[0-9]*' | awk 'END{printf \"%.0f\n\", (NR+0.1)/2}'"
      end
    end

    def memory(system)
      if system == 'linux'
        "free -m |awk '{print $2}'| sed -n 2p"
      elsif system == 'freebsd'
        "dmesg | awk '/real memory/ {print $4/1024/1024}'"
      end
    end

    def primary_network_interface
      "ip route get 8.8.8.8 | awk '{if($1==\"8.8.8.8\") print $5}'"
    end

    def network_interfaces_amount
      "ip -o link show | awk '{print $1}' | wc -l"
    end

    def primary_network_ip
      "ip route get 8.8.8.8 | awk '{if($1==\"8.8.8.8\") print $7}'"
    end

    def ip_addresses
      "ip -o addr show | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq"
    end

    def recipe_script(file)
      "echo $VM_IDENTIFIER>>#{file};"\
      "echo $IP_ADDRESS>>#{file};"\
      "echo $HOSTNAME>>#{file};"\
      "echo $ROOT_PASSWORD>>#{file};"\
      "echo $OPERATING_SYSTEM>>#{file};"\
      "echo $OPERATING_SYSTEM_DISTRO>>#{file};"\
      "echo $OPERATING_SYSTEM_ARCH>>#{file};"\
      "echo $OPERATING_SYSTEM_EDITION>>#{file};"\
    end

    def zabbix_agent_status
      'service autoscale-agent status;echo $?'
    end

    def drop_caches
      'sync && echo 3 > /proc/sys/vm/drop_caches && echo $?'
    end

    def domain
      "cat /etc/resolv.conf | grep domain | awk '{print $2}'"
    end

    def install_ioping_ubuntu
      'echo "nameserver 8.8.8.8" >> /etc/resolv.conf && sudo apt-get -y install ioping && echo $?'
    end

    def install_ioping_centos
      'wget http://dl.fedoraproject.org/pub/epel/7/x86_64/i/ioping-1.0-1.el7.x86_64.rpm ; yum install -y ioping-1.0-1.el7.x86_64.rpm'
    end

    def measure_read_iops(partition)
      "ioping -p 100 -c 200 -i 0 -q /dev/#{partition} | awk '{ print \\$3 }' | sed -n 2p"
    end

    def measure_write_iops(mount_path)
      "cd #{mount_path} && dd if=/dev/zero of=testfile bs=512K count=500; ioping -p 100 -c 200 -i 0 -q -WWW testfile | awk '{ print \\$3 }' | sed -n 2p"
    end

    def measure_read_throughput(partiiton)
      "dd if=/dev/#{partiiton} of=/dev/null bs=512K count=500 iflag=direct 2>&1 | sed -n 3p | awk '{print \\$8}'"
    end

    def measure_write_throughput(mount_path)
      "cd #{mount_path} && dd if=/dev/zero of=test_io_write oflag=direct count=500 bs=512K 2>&1 | sed -n 3p | awk '{print \\$8}'"
    end
  end

  module OnHypervisor
    extend self

    def cpu_shares(hypervisor_type, vm_identifier)
      if hypervisor_type == 'kvm'
        "virsh schedinfo #{vm_identifier} | grep cpu_shares"
      elsif hypervisor_type == 'xen'
        "xm sched-credit | grep #{vm_identifier} || echo 'false'"
      end
    end

    def force_remount_data(remote_ip)
      "umount -f /data;mount -t nfs #{remote_ip}:/data/ /data/"
    end

    def data_mounted
      'mount|grep data'
    end

    def find_file(path, file_name)
      "find #{path} -name #{file_name}"
    end

    def nic_rate_limit(nic_identifier)
      "tc -s qdisc ls dev #{nic_identifier} | head -1 | awk '{print \\$8/1000}'"
    end

    def firewall_rules(remote_ip)
      "iptables -nL FORWARD | grep -wc '#{remote_ip}'"
    end
  end

  module OnControlPanel
    extend self

    def ping(remote_ip)
      "ping -c1 #{remote_ip};echo $?"
    end

    def nc(remote_ip, port)
      "nc -v -w1 #{remote_ip} #{port} < /dev/null;echo $?"
    end

    def enable_incremantal_autobackups
      'cd /onapp/interface;RAILS_ENV=production bundle exec rake vm:switch_to_incremental_auto_backups;echo $?'
    end

    def enable_normal_autobackups
      'cd /onapp/interface;RAILS_ENV=production bundle exec rake vm:switch_to_normal_auto_backups;echo $?'
    end

    def remove_federation_cache
      'rm -rf /onapp/interface/tmp/cache/6E6 /onapp/interface/tmp/cache/8E5 /onapp/interface/tmp/cache/9C8; echo $?'
    end

    def license
      'grep -q "staging-dashboard.onapp.com" /onapp/interface/config/environments/production.rb; echo $?'
    end

    def run_autohealing_task
      'cd /onapp/interface; RAILS_ENV=production rake storage_auto_healing:perform_hourly'
    end

    def disable_io_limiting
      'sed -i "s/io_limiting_enabled: true/io_limiting_enabled: false/" /onapp/interface/config/on_app.yml'
    end

    def enable_io_limiting
      'sed -i "s/io_limiting_enabled: false/io_limiting_enabled: true/" /onapp/interface/config/on_app.yml'
    end

    def restart_httpd
      'sudo service httpd restart'
    end

    def location_id_of_cdn_server(type_of_server, label_of_cdn_server)
      "cd /onapp/interface; RAILS_ENV=production rails runner \"p Aflexi::#{type_of_server}.get(name: '#{label_of_cdn_server}').first.location.id\""
    end
  end

  module OnCloudbootHypervisor
    extend self

    # general

    def get_vdisks_list
      "onappstore list | grep -i node| sed -e 's/Node \\[//' -e 's/\\]//'"
    end

    def get_frontend_uuid
      "onappstore getid | awk '{print \\$5}' | sed 's/uuid=//'"
    end

    def online_vdisks(vdisks_list, frontend_uuid)
      "for i in #{vdisks_list.join(" ")};do onappstore online uuid=\\$i frontend_uuid=#{frontend_uuid};done && echo $? || echo $?"
    end

    def online_vdisk(vdisk, frontend_uuid)
      "onappstore online uuid=#{vdisk} frontend_uuid=#{frontend_uuid} && echo $?"
    end

    def get_vdisk_members(vdisk)
      "onappstore diskinfo uuid=#{vdisk} | awk '{print \\$17}' | sed -e 's/members=//' -e 's/,/ /g' "
    end

    def get_frontend_node_members
      "diskhotplug list | grep -i nodeid |sed -e 's/.*,NodeID://g' -e 's/)//'"
    end

    # degraded vdisk

    def offline_vdisks(vdisks_list)
      "for i in #{vdisks_list.join(" ")};do onappstore offline uuid=\\$i ;done && echo $? || echo $?"
    end

    def get_bdev_connections
      "ps ax | grep -v grep | grep bdevcli | awk '{print \\$12, \\$1}' | sort -b | awk '{print \\$2}'"
    end

    def get_bdev_connections_per_vdisk(vdisk)
      "ps ax | grep -v grep | grep bdevcli | grep #{vdisk} | awk '{print \\$12, \\$1}' | sort -b | awk '{print \\$2}'"
    end

    def kill_one_nbd(bdev_connections)
      "count=1 && for i in #{bdev_connections.join(" ")};do if [[ \\$count%4 -eq 0 ]];then kill -9 \\$i;fi; let count+=1;done"
    end

    def get_degraded_vdisks
      "getdegradedvdisks | grep degraded_vdisks | wc -l"
    end

    def get_degraded_vdisk(vdisk)
      "getdegradedvdisks | grep degraded_vdisks.*#{vdisk} | wc -l"
    end

    # partial memberlist

    def get_node(vdisk)
      "onappstore diskinfo uuid=#{vdisk} | awk '{print \\$17}' | sed -e 's/members=//' -e 's/,/ /g' | awk '{print \\$1}'"
    end

    def forget_node(vdisk, get_node)
      "onappstore forget forgetlist=#{get_node} vdisk_uuid=#{vdisk}"
    end

    def get_partial_memberlist_vdisk
      "getdegradedvdisks | grep -i vdisks_with_partial_memberlist | wc -l"
    end

    # vdisk with no redundancy

    def vdisk_with_no_redundancy
      "getdegradedvdisks | grep -i vdisks_with_no_redundancy | wc -l"
    end

    # partially online

    def kill_three_nbds(bdev_connections)
      "for i in #{bdev_connections.drop(1).join(" ")};do  kill -9 \\$i;done"
    end

    def get_partially_online_vdisks(vdisk)
      "getdegradedvdisks | grep -i partially.*#{vdisk} | wc -l"
    end

    # other degraded states

    def get_controller_ip
      "onappstore getid | awk '{print \\$2}' | sed -r 's/([0-9]*)[a-z]*./\1/' | sed 's/,/ /'".
          gsub(/[\u0001-\u001A]/ , '')
    end

    def get_node_file(controller_ip, vdisk, node)
      "ssh -T -o StrictHostKeyChecking=no -q #{controller_ip} 'ls /DB/NODE-#{node}/#{vdisk}*' | grep -i -v warning"
    end

    def remove_node_file(controller_ip, file_path)
      "ssh -T -o StrictHostKeyChecking=no -q #{controller_ip} 'rm -rf #{file_path}'"
    end

    def get_other_degraded_state_vdisk(vdisk)
      "getdegradedvdisks | grep -i missing_active_members.*#{vdisk} | wc -l"
    end

    # partial nodes

    def make_partial_node(controller_ip)
      "ssh -T -o StrictHostKeyChecking=no -q #{controller_ip} 'killall python;/etc/init.d/isd stop'"
    end

    def get_partial_nodes
      "getdegradednodes | grep -i partial_nodes | wc -l"
    end

    # inactive nodes

    def make_inactive_node
      "/etc/init.d/SANController stop"
    end

    def get_inactive_nodes
      "getdegradednodes | grep -i inactive_nodes | wc -l"
    end

    def make_active_node
      "/etc/init.d/SANController start"
    end

    # nodes with delayed ping

    def make_nodes_with_delayed_ping(controller_ip)
      "ssh -T -o StrictHostKeyChecking=no -q #{controller_ip} '/etc/init.d/isd stop'"
    end

    def get_delayed_ping_nodes
      "getdegradednodes | grep -i delayedping_nodes | wc -l"
    end

    def repair_nodes_with_delayed_ping(controller_ip)
      "ssh -T -o StrictHostKeyChecking=no -q #{controller_ip} '/etc/init.d/isd start'"
    end

    # node with high utilization

    def get_max_vdisk_size
      "onappstore listds | grep -i max-new-vdisk | sed -e 's/.*k//' -e 's/ //g'"
    end

    def get_utilisation_node
      "getdegradednodes | grep -i utilisation_over_90 | wc -l"
    end

    def ddwrapper_vdisk_4096k(vdisk)
      "ddwrapper device=/dev/mapper/#{vdisk} bs=4096K && echo $?"
    end

    def ddwrapper_vdisk_4k(vdisk)
      "ddwrapper device=/dev/mapper/#{vdisk} bs=4K && echo $?"
    end
    # inactive controller

    def destroy_controller
      "virsh list | grep -i storage | virsh destroy \\$(awk '{print \\$1}')"
    end

    def get_storage_controller
      "virsh list | grep -i storage"
    end

    # unreferenced nbds

    def remove_mapper_device(vdisk)
      "dmsetup remove #{vdisk} && echo $?"
    end

    # stale cache volumes

    def acquire_cache_vdisk(vdisk, key="foo")
      "onappstore acquire uuid=#{vdisk} key=#{key}"
    end

    def online_cache_vdisk(vdisk, frontend_node, key="foo", cache="writethrough")
      "onappstore online uuid=#{vdisk} frontend_uuid=#{frontend_node} key=#{key} cache=#{cache}"
    end

    def reboot_hv
      "init 6"
    end

    # inactive cache

    def get_cache_mapper(vdisk)
      "ls /dev/mappers | grep #{vdisk} && echo $?"
    end

    def get_cache_lvs(vdisk)
      "lvs | grep #{vdisk} && echo $?"
    end
  end
end
