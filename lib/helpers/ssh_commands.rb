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
  end

  module OnControlPanel
    extend self

    def ping(remote_ip)
      "ping -c1 #{remote_ip};echo $?"
    end

    def nc(remote_ip, port)
      "nc -z -w1 #{remote_ip} #{port};echo $?"
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
  end
end