require 'helpers/api_client'
require 'helpers/logger'
require 'helpers/transaction'
require 'iso'
require 'mechanize'
require 'active_support/all'
require 'hashie'

class IsoActions
  include ApiClient, Log

  attr_reader :iso

  def initialize
    auth unless self.conn
  end

  def precondition
    @iso = Iso.new(self)
    data = {'label' => 'iso_api_test',
            'make_public' => '0',
            'min_memory_size' => '256',
            'version' => '1.0',
            'operating_system' => 'Linux',
            'operating_system_distro' => 'Fedora',
            'virtualization' => ["xen", "kvm"],
            'file_url' => 'http://templates.repo.onapp.com/Linux-iso/Fedora-Server-netinst-x86_64-21.iso'}
    @iso.create(data)

    self
  end
end