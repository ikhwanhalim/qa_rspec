module SshCommands
  module RHEL
    extend self

    def update_os
      'yum update -y --nogpgcheck;echo $?'
    end
  end

  module UBUNTU
    extend self

    def update_os
      'apt-get update;apt-get --allow-unauthenticated upgrade -y;echo $?'
    end
  end

  module FreeBSD
    extend self
  end

  module Gentoo
    extend self

    def update_os
      'emerge --sync;emerge --update --deep --with-bdeps=y @world'
    end
  end

  module OpenSUSE
    extend self

    def update_os
      'zypper refresh;zypper update'
    end
  end

  module ArchLinux
    extend self

    def update_os
      'pacman -Syu --noconfirm'
    end
  end
end