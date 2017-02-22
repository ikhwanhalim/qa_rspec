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
    #remove_after_install  temporary comment out this method to avoid deleting templates on CPs that are using shared resources
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

  def remove_after_install
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
    template_list = Array.new
    interface.get('/templates/available').map(&:remote_template).each do |t|
      if t.operating_system == operating_system && !t.cdn && !t.application_server && t.operating_system_distro !='lbva'
        template_list << t.manager_id
      end
    end
    interface.get('/templates/all').map(&:image_template).each do |t|
      if t.operating_system == operating_system && !t.cdn && !t.application_server && t.operating_system_distro !='lbva'
        template_list << t.manager_id
      end
    end
    template_list.sample
  end

  private

  def info_update(info)
    info.each { |k,v| instance_variable_set("@#{k}", v) }
  end
end