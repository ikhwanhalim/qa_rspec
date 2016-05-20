class ImageTemplate
  include TemplateManager

  attr_reader :interface, :allow_resize_without_reboot, :allowed_hot_migrate, :allowed_swap, :application_server,
              :backup_server_id, :baremetal_server, :cdn, :checksum, :created_at, :disk_target_device,
              :ext4, :file_name, :id, :initial_password, :initial_username, :label, :manager_id, :min_disk_size,
              :min_memory_size, :operating_system, :operating_system_arch, :operating_system_distro,
              :operating_system_edition, :operating_system_tail, :parent_template_id, :remote_id,
              :resize_without_reboot_policy, :smart_server, :state, :template_size, :updated_at, :user_id,
              :version, :virtualization

  def initialize(interface)
    @interface = interface
  end

  def find_by_manager_id(manager_id)
    info = get_template(manager_id)
    info_update(info)
    self
  end

  def find_by_id(id)
    info = interface.get("/templates/#{id}").image_template
    info_update(info)
    self
  end

  def remove
    interface.delete("/templates/#{id}")
    wait_for_transaction(id, "ImageTemplateBase", "destroy_template")
  end

  def db_enable_hotresize
    interface.query("update templates set resize_without_reboot_policy='---\n:xen:\n  :centos5: 15\n  :centos6: 15\n:kvm:\n  :centos5: 15\n  :centos6: 15\n' where id=#{id}")
    interface.query("update templates set allow_resize_without_reboot=1 where id=#{id}")
  end

  private

  def info_update(info)
    info.each { |k,v| instance_variable_set("@#{k}", v) }
  end
end