class Ova
  include Transaction, TemplateManager
  attr_reader :interface, :errors, :id, :label, :min_memory_size, :version, :operating_system, :operating_system_distro,
              :virtualization, :user_id, :min_disk_size, :file_name, :allowed_swap, :type, :backup_server_id, :manager_id

  def initialize(interface)
    @interface = interface
  end

  def build_data
    {
        label: @label || "OVA-#{SecureRandom.hex(4)}",
        make_public: '0',
        min_memory_size: '512',
        min_disk_size: 6,
        version: '1.0',
        operating_system: 'linux',
        operating_system_distro: 'rhel',
        virtualization: ["kvm"],
        backup_server_id: interface.backup_server.id,
        file_url: 'https://sourceforge.net/projects/virtualappliances/files/Linux/CentOS/CentOS-6.4-i386-minimal.ova'
    }
  end

  def create(**params)
    response = interface.post("/template_ovas", { image_template_ova: build_data.merge(params) })
    response_handler response
    return if response['errors']
    wait_for_downloading
    wait_for_extracting
    wait_for_importing
    wait_for_importing_disk_partition
    wait_for_parsing_fstab
    wait_for_converting_ova_to_template
  end

  def edit(**params)
    response_handler interface.put(route, { image_template_ova: build_data.merge(params) })
  end

  def make_public
    response_handler interface.post("#{route}/make_public")
  end

  def find(ova_id)
    response_handler interface.get("/template_ovas/#{ova_id}")
  end

  def exists_in?(folder: 'data')
    ova_file = file_name.sub(/(\.[a-z]+)+/, "")
    command = folder == 'data' ? "ls /data/ |grep #{ova_file+='.ova'}" : "ls /onapp/templates/ |grep #{ova_file+='.tar.gz'}"
    interface.backup_server.ssh_execute(command).join.include?(ova_file)
  end

  def remove
    interface.delete(route)
    if api_response_code != '204'
      Log.error('OVA has not been removed')
      return false
    end
    wait_for_removing
    Log.warn('OVA has been removed from /onapp/templates/') unless exists_in?(folder:'templates')
  end

  def wait_for_downloading
    wait_for_transaction(id, 'ImageTemplateBase', 'download_ova')
  end

  def wait_for_extracting
    wait_for_transaction(id, 'ImageTemplateBase', 'extract_ova')
  end

  def wait_for_importing
    wait_for_transaction(id, 'ImageTemplateBase', 'import_ovf')
  end

  def wait_for_importing_disk_partition
    wait_for_transaction(id, 'ImageTemplateBase', 'import_disk_partition')
  end

  def wait_for_parsing_fstab
    wait_for_transaction(id, 'ImageTemplateBase', 'parse_fstab')
  end

  def wait_for_converting_ova_to_template
    wait_for_transaction(id, 'ImageTemplateBase', 'convert_ova_to_template')
  end

  def wait_for_removing
    wait_for_transaction(id, 'ImageTemplateBase', 'destroy_ova')
  end

  def wait_for_copy
    wait_for_transaction(id, 'ImageTemplateBase', 'copy_ova')
  end

  def wait_for_delete_ova_files
    wait_for_transaction(id, 'ImageTemplateBase', 'delete_ova_files')
  end

  def route
    "/template_ovas/#{id}"
  end

  def api_response_code
    interface.conn.page.code
  end

  private

  def response_handler(response)
    @errors = response['errors']
    image_template_ova = if response['image_template_ova']
                           response['image_template_ova']
                         elsif !@errors
                           interface.get(route)['image_template_ova']
                         end
    return Log.warn(@errors) if @errors
    image_template_ova.each { |k, v| instance_variable_set("@#{k}", v)}
  end
end