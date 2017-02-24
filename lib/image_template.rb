class ImageTemplate
  include TemplateManager

  attr_reader :interface, :allow_resize_without_reboot, :allowed_hot_migrate, :allowed_swap, :application_server,
              :backup_server_id, :baremetal_server, :cdn, :checksum, :created_at, :disk_target_device,
              :ext4, :file_name, :id, :initial_password, :initial_username, :label, :manager_id, :min_disk_size,
              :min_memory_size, :operating_system, :operating_system_arch, :operating_system_distro,
              :operating_system_edition, :operating_system_tail, :parent_template_id, :remote_id,
              :resize_without_reboot_policy, :smart_server, :state, :template_size, :updated_at, :user_id,
              :version, :virtualization, :type

  def initialize(interface)
    @interface = interface
  end

  def find_by_manager_id(manager_id)
    remove_after_install
    manager_id = manager_id ? manager_id : select_template_by_os
    info = get_template(manager_id)
    info_update(info)
    self
  end

  def find_by_id(id)
    info = interface.get("/templates/#{id}").image_template
    info_update(info)
    self
  end

  def find_by_label(label)
    interface.get("/templates").detect do |t|
      t.image_template.label == label
    end.image_template
  end

  def remove(template_id = nil)
    interface.delete("/templates/#{template_id || id}")
    wait_for_transaction(template_id || id, "ImageTemplateBase", "destroy_template")
  end

  def db_enable_hotresize
    interface.query("update templates set resize_without_reboot_policy='---\n:xen:\n  :centos5: 15\n  :centos6: 15\n:kvm:\n  :centos5: 15\n  :centos6: 15\n' where id=#{id}")
    interface.query("update templates set allow_resize_without_reboot=1 where id=#{id}")
  end

  def remove_after_install(enable: false)
    return Log.info("The delete_template_source_after_install option won't be enabled at CP settings") unless enable
    if defined?(interface.settings)
      if interface.settings
        unless interface.settings.delete_template_source_after_install
          interface.settings.setup(delete_template_source_after_install: true)
        end
        Log.info('Template will be removed after install')
      else
        Log.warn('Settings has not been defined')
      end
    end
  end

  def select_template_by_os(operating_system: 'linux')
    templates =  get_available.map(&:remote_template) + get_installed.map(&:image_template)
    template_list = []
    templates.each{ |t| template_list << t.manager_id if template_compatible?(t, operating_system)}
    template_list.sample
  end

  def template_compatible?(template, operating_system)
    template.operating_system == operating_system && !template.cdn && !template.application_server && template.operating_system_distro !='lbva'
  end

  private

  def info_update(info)
    info.each { |k,v| instance_variable_set("@#{k}", v) }
  end
end