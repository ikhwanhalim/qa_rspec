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

    def disk_size(mount_point)
      "df -h | awk '{if($6==\"#{mount_point}\") print $2}'"
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

    def primary_network_ip
      "ip route get 8.8.8.8 | awk '{if($1==\"8.8.8.8\") print $7}'"
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
  end
end