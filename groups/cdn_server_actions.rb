class CdnServerActions
  include ApiClient, SshClient, Log

  IDENTIFIER          = ENV['IDENTIFIER_CDN']
  HVZ_ID              = ENV['HVZ_ID']
  TEMPLATE_MANAGER_ID = 'cdn'
  TEMPLATE_VM_ID      = ENV['TEMPLATE_VM_ID']

  attr_accessor :hypervisor, :template
  attr_reader   :settings, :virtual_machine

  def precondition
    Log.error("The CDN_SERVER variable is not set, please do it") unless CdnServer::CDN_SERVER

    @virtual_machine = CdnServer.new(self)
    @settings = Settings.new(self)

    if IDENTIFIER
      @virtual_machine.find(IDENTIFIER)
    else
      check_staging if CdnServer::CDN_SERVER_TYPE == 'streaming'
      @template = ImageTemplate.new(self)
      @template.find_by_manager_id(TEMPLATE_MANAGER_ID)

      @hypervisor = Hypervisor.new(self)
      @hypervisor.find_cdn_supported(HVZ_ID)

      @virtual_machine.create
    end

    self
  end

  def check_staging
    staging = run_on_cp SshCommands::OnControlPanel.license
    if staging
      Log.info("Congrat, you are on the staging CP")
    else
      Log.error("Tests for STREAM server should be run on staging CP only, otherwise you should pay 50$")
    end
  end
end