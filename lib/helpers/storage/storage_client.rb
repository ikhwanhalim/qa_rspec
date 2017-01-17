module StorageClient
  class API
    TIMEOUT = 300

    VDISK_STATE_START_REPLICATION = 21
    VDISK_STATE_STOP_REPLICATION  = 22
    VDISK_GET_MAX_RESIZE          = 43
    TUNNEL_STATE_PREPARE          = 0
    TUNNEL_STATE_ADD              = 1
    TUNNEL_STATE_REMOVE           = 2
    NODE_STATE_GET_CACHE_ORPHANS  = 7
    VDISK_STATE_FORGET_CACHE      = 51
    NODES_FORGET                  = 0

    attr_accessor :type, :url, :params, :hook

    class Error < StandardError
      attr_reader :signature

      def initialize(msg = nil, signature = nil)
        @signature = signature
        super(msg)
      end
    end

    ServerError     = Class.new(Error)
    Failure         = Class.new(Error)
    BadResponse     = Class.new(Error)
    ConnectionError = Class.new(Error)



    class << self
      def query(*args, &block)
        new(*args, &block).execute
      end

      def is_repair_vdisk(data_store_uuid, disk_uuid, &block)
        query(:put, "is/Datastore/#{data_store_uuid}/VDisk/#{disk_uuid}", state: '6', &block)
      end

      def is_membership_repair_vdisk(data_store_uuid, disk_uuid, node_uuid, &block)
        params = { state: '8' }
        params[:memberlist] = node_uuid.to_s if node_uuid.present?
        query(:put, "is/Datastore/#{data_store_uuid}/VDisk/#{disk_uuid}", params, &block)
      end

      def is_resync_status_vdisk(data_store_uuid, disk_uuid, &block)
        query(:put, "is/Datastore/#{data_store_uuid}/VDisk/#{disk_uuid}", state: '9', &block)
      end

      def is_create_vdisk(data_store_uuid, attrs, &block)
        attrs.slice!(:size, :name)
        query(:post, "is/Datastore/#{data_store_uuid}/VDisk", attrs, &block)
      end

      def is_delete_vdisk(disk_uuid, &block)
        query(:delete, "is/VDisk/#{disk_uuid}", {}, &block)
      end

      def is_get_vdisk_io_stat_info(disk_uuid, start, finish, &block)
        query(:get, "is/VDiskIOStat/#{disk_uuid}", { start: start.to_i, end: finish.to_i }, &block)
      end

      def is_get_vdisk_max_resize(data_store_uuid, disk_uuid, &block)
        query(:put, "is/Datastore/#{data_store_uuid}/VDisk/#{disk_uuid}", state: VDISK_GET_MAX_RESIZE, &block)
      end

      def is_forget_node(node_uuid, disk_uuid, &block)
        params = { state: NODES_FORGET.to_s, forgetlist: node_uuid }
        params[:vdi_uuid] = disk_uuid if disk_uuid.present?
        query(:put, "is/Node", params, &block)
      end

      def is_forget_nodes(node_uuids, &block)
        params = { state: NODES_FORGET.to_s, forgetlist: node_uuids.join(',') }
        query(:put, "is/Node", params, &block)
      end

      def is_get_hv_info(&block)
        query(:get, 'is/HV', {}, &block)
      end

      def is_get_node_info(node_uuid, &block)
        url = 'is/Node'
        url += "/#{node_uuid}" if node_uuid.present?
        query(:get, url, {}, &block)
      end

      def is_adjust_node(node_uuid, performance, &block)
        query(:put, "is/Node/#{node_uuid}", { state: '1', performance: performance }, &block)
      end

      def is_get_node_io_stat_info(node_uuid, start, finish, &block)
        query(:get, "is/NodeIOStat/#{node_uuid}", { start: start.to_i, end: finish.to_i }, &block)
      end

      def is_get_vdisk_info(disk_uuid, &block)
        url = 'is/VDisk'
        url += "/#{disk_uuid}" if disk_uuid.present?
        query(:get, url, {}, &block)
      end

      def is_get_cached_vdisk_info(disk_uuid, &block)
        url = 'is/VDisk'
        url += "/#{disk_uuid}" if disk_uuid.present?
        query(:put, url, state: 18, &block)
      end

      def is_get_data_store_info(data_store_uuid, &block)
        url = 'is/Datastore'
        url += "/#{data_store_uuid}" if data_store_uuid.present?
        query(:get, url, {}, &block)
      end

      def is_node_add_datastore(data_store_uuid, node_uuid, &block)
        url = "is/Datastore/#{data_store_uuid}"
        query(:put, url, state: '0', member_uuid: node_uuid, &block)
      end

      def is_node_remove_datastore(data_store_uuid, node_uuid, &block)
        url = "is/Datastore/#{data_store_uuid}"
        query(:put, url, state: '1', member_uuid: node_uuid, &block)
      end

      def is_delete_datastore(data_store_uuid, &block)
        query(:delete, "is/Datastore/#{data_store_uuid}", {}, &block)
      end

      def is_create_datastore(attrs, &block)
        params = attrs.slice(:stripes, :replicas, :overcommit, :name)
        params[:owners] = attrs[:owner_ids].join(',')
        params[:membership_count] = attrs[:owner_ids].size
        query(:post, 'is/Datastore', params, &block)
      end

      def is_rename_datastore(data_store_uuid, new_name, &block)
        query(:put, "is/Datastore/#{data_store_uuid}", { state: 7, newname: new_name }, &block)
      end

      def is_get_degraded_vdisks(data_store_uuid, &block)
        query(:put, "is/Datastore/#{data_store_uuid}", { state: 2 }, &block)
      end

      def is_get_degraded_nodes(data_store_uuid, &block)
        query(:put, "is/Datastore/#{data_store_uuid}", { state: 3 }, &block)
      end

      def stop_handler(options = {}, &block)
        options.merge!(state: 1)
        query(:put, 'is/Storagehandler/1', options, &block)
      end

      def start_handler(options = {}, &block)
        options.merge!(state: 0)
        query(:put, 'is/Storagehandler/1', options, &block)
      end

      def is_get_controllers(&block)
        query(:get, 'is/Controller', {}, &block)
      end

      def is_stop_controller(controller_uuid, &block)
        query(:put, "is/Controller/#{controller_uuid}", { state: 2 }, &block)
      end

      def is_start_controller(controller_uuid, &block)
        query(:put, "is/Controller/#{controller_uuid}", { state: 1 }, &block)
      end

      def is_fix_partial_online(data_store_uuid, disk_uuid, node_uuid, &block)
        query(:put, "is/Datastore/#{data_store_uuid}/VDisk/#{disk_uuid}", { state: 17, frontend_uuid: node_uuid }, &block)
      end

      def is_get_node_extended_info(node_uuid, &block)
        query(:put, "is/Node/#{node_uuid}", { state: 3 }, &block)
      end

      def is_fix_out_of_space_node(node_uuid, &block)
        query(:put, "is/Node/#{node_uuid}", { state: 4 }, &block)
      end

      def is_get_drive_smart_info(drive_uuid, &block)
        query(:put, "is/Drive/#{drive_uuid}", { state: 5, testmode: 'attrib', cached: 'true' }, &block)
      end

      def is_get_disks_distribution(data_store_uuid, &block)
        query(:put, "is/Datastore/#{data_store_uuid}", { state: 6 }, &block)
      end

      def is_prepare_tunnel(tunnel_uuid, &block)
        query(:put, "is/Tunnel/#{tunnel_uuid}", { state: TUNNEL_STATE_PREPARE, destination: nil }, &block)
      end

      def is_get_frontend_info(&block)
        query(:get, "is/Id", {}, &block)
      end

      def is_add_tunnel(tunnel_uuid, destination, ports, &block)
        query(:put, "is/Tunnel/#{tunnel_uuid}", { state: TUNNEL_STATE_ADD, destination: destination, ports: ports }, &block)
      end

      def is_remove_tunnel(tunnel_uuid, &block)
        query(:put, "is/Tunnel/#{tunnel_uuid}", { state: TUNNEL_STATE_REMOVE, destination: nil }, &block)
      end

      def is_list_tunnels(&block)
        query(:get, "is/Tunnel", {}, &block)
      end

      def is_start_replication(disk_uuid, frontend_uuid, portmap, &block)
        query(:put, "is/VDisk/#{disk_uuid}", { state: VDISK_STATE_START_REPLICATION, frontend_uuid: frontend_uuid, portmap: portmap }, &block)
      end

      def is_stop_replication(disk_uuid, frontend_uuid, portmap, &block)
        params = { state: VDISK_STATE_STOP_REPLICATION, frontend_uuid: frontend_uuid, portmap: portmap }
        params.merge!(force: 'true') if portmap.blank?
        query(:put, "is/VDisk/#{disk_uuid}", params, &block)
      end

      def is_get_cache_orphans(node_uuid, &block)
        query(:put, "is/Node/#{node_uuid}", { state: NODE_STATE_GET_CACHE_ORPHANS }, &block)
      end

      def is_forget_cache(data_store_uuid, disk_uuid, host_id, &block)
        query(:put, "is/Datastore/#{data_store_uuid}/VDisk/#{disk_uuid}", { state: VDISK_STATE_FORGET_CACHE, hostid: host_id, lv: 'true' }, &block)
      end
    end

    def initialize(type, url, params, &block)
      self.type = type
      self.url = url
      self.params = params
      self.hook = block
    end

    def execute
      reply = JSON.parse(make_request).with_indifferent_access

      if reply[:result] && reply[:result] != 'SUCCESS'
        raise Failure.new((reply[:Error] || reply[:error] || reply.to_s), signature)
      end

      reply
    rescue Error => e
      raise e
    rescue Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::ECONNREFUSED, Errno::ETIMEDOUT => e
      raise ConnectionError.new("#{signature} #{e.class} #{e.message}")
    rescue => e
      raise Error.new("#{signature} #{e.class} #{e.message}")
    end

    def full_url
      @full_url ||= "#{StorageActions.new.precondition.hypervisor.ip_address}:8080/#{url}"
    end

    def request_params
      {
          method:       type,
          url:          full_url,
          timeout:      TIMEOUT,
          open_timeout: TIMEOUT,
          payload:      params.to_json,
      }
    end

    def signature
      [type.upcase, full_url, params.presence && params.to_json].
          compact.
          join(' ')
    end

    def make_request
      hook.call(:signature, signature) if hook.present?
      reply = RestClient::Request.execute(request_params)
      hook.call(:reply, reply) if hook.present?

      raise ServerError.new(signature) if reply.code == 500
      raise BadResponse.new(signature) if reply.code != 200

      reply
    end
  end
end