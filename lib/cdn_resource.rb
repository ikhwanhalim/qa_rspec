class CdnResource
  include Waiter

  attr_reader :interface, :id, :origins, :status, :cdn_hostname, :push_origin_hostname, :secondary_hostnames, :ssl_on,
              :ssl, :cdn_ssl_certificate_id, :cname, :resource_type, :user_id, :last_24h_cost, :cdn_reference, :origins,
              :edge_groups, :country_access_policy, :hotlink_policy, :domains, :ip_access_policy, :ip_addresses,
              :secondary_hostnames, :flv_pseudo_on, :mp4_pseudo_on, :limit_rate, :limit_rate_after, :url_signing_on,
              :password_on, :url_signing_key, :password_unauthorized_html, :origin_policy, :cache_expiry, :proxy_cache_key,
              :http_bot_blocked, :ignore_set_cookie_on, :proxy_read_time_out, :proxy_connect_time_out, :hls_on,
              :hls_force_cache, :countries, :passwords, :token_auth_secure_paths, :token_auth_backup_key, :token_auth_on,
              :token_auth_primary_key, :secure_wowza_token, :secure_wowza_on, :publishing_location, :failover_publishing_location,
              :letsencrypt_ssl_on

  def initialize(interface)
    @interface = interface
  end

  def attrs_update(attrs=nil)
    attrs ||= interface.get(route_cdn_resource)
    if attrs.values.map(&:class).include?(Array)
      attrs.each { |k,v| instance_variable_set("@#{k}", v) }
    else
      attrs.values.first.each { |k,v| instance_variable_set("@#{k}", v) }
    end

    self
  end

  def create_http_resource(advanced: false, type: '', **params)
    if advanced
      data = basic_params(type).merge(advanced_common_http_params)
      data.merge!(common_pull_params)         if type == 'HTTP_PULL'
      data.merge!(advanced_http_pull_params)  if type == 'HTTP_PULL'
      data.merge!(common_push_params)         if type == 'HTTP_PUSH'
    else
      data = basic_params(type)
      data.merge!(common_pull_params)         if type == 'HTTP_PULL'
      data.merge!(common_push_params)         if type == 'HTTP_PUSH'
    end

    data.merge!(params)
    data.delete(:origin) if data.key?(:origins)
    json_response = interface.post("#{route_cdn_resources}", cdn_resource: data)
    attrs_update json_response
  end

  def create_vod_stream_resource(advanced: false, type: '', point: nil, **params)
    if advanced
      data = basic_params(type).merge(advanced_common_vod_stream_params)
      data.merge!(common_stream_params(point))  if type == 'STREAM_LIVE'
      data.merge!(advanced_stream_params)       if type == 'STREAM_LIVE'
      data.merge!(common_pull_params)           if type == 'STREAM_VOD_PULL'
      data.merge!(common_push_params)           if type == 'STREAM_VOD_PUSH'
    else
      data = basic_params(type)
      data.merge!(common_stream_params(point))  if type == 'STREAM_LIVE'
      data.merge!(common_pull_params)           if type == 'STREAM_VOD_PULL'
      data.merge!(common_push_params)           if type == 'STREAM_VOD_PUSH'
    end

    data.merge!(params)
    data.delete(:origin) if data.key?(:origins)
    json_response = interface.post("#{route_cdn_resources}", cdn_resource: data)
    attrs_update json_response
  end

  def advanced_common_http_params
    {
       secondary_hostnames: ["sec.#{Faker::Internet.domain_name}", "sec.#{Faker::Internet.domain_name}"],
       ip_access_policy: 'BLOCK_BY_DEFAULT',
       ip_addresses: "#{Faker::Internet.ip_v4_address},#{Faker::Internet.ip_v4_address}",
       country_access_policy: 'BLOCK_BY_DEFAULT',
       countries: ["AL", "GT"],
       hotlink_policy: 'BLOCK_BY_DEFAULT',
       domains: "#{Faker::Internet.domain_name} #{Faker::Internet.domain_name}",
       url_signing_on: '1',
       url_signing_key: Faker::Internet.password(8,12),
       cache_expiry: '45',
       password_on: '1',
       form_pass: {
           user: [Faker::Internet.user_name],
           pass: [Faker::Internet.password],
       },
       password_unauthorized_html: 'YOU ARE NOT AUTHORIZED',
       flv_pseudo_on: '1',
       mp4_pseudo_on: '0',
       limit_rate: '150',
       limit_rate_after: '1',
       http_bot_blocked: '1',
       ignore_set_cookie_on: '0'
    }
  end

  def advanced_http_pull_params
    {
       proxy_cache_key: '$host$uri',
       proxy_read_time_out: '60',
       proxy_connect_time_out: '20',
       origin_policy: 'HTTP',
       hls_on: 0,
       hls_force_cache: 0
    }
  end

  def common_pull_params
    {
       origin: Faker::Internet.ip_v4_address
    }
  end

  def basic_params(type)
    {
       resource_type: type,
       cdn_hostname: Faker::Internet.domain_name,
       edge_group_ids: [4],  # this value will be taken during performing rspec
    }
  end

  def common_push_params
    {
       ftp_password: Faker::Internet.password(32)
    }
  end

  def common_stream_params(point)
    {
       publishing_point: point,
       publishing_location: "http://#{Faker::Internet.domain_name}"
    }
  end

  def advanced_common_vod_stream_params
    {
       hotlink_policy: 'BLOCK_BY_DEFAULT',
       domains: "#{Faker::Internet.domain_name} #{Faker::Internet.domain_name}",
       country_access_policy: 'BLOCK_BY_DEFAULT',
       countries: ["AL", "GT"],
       secure_wowza_on: 1,
       secure_wowza_token: Faker::Internet.password(16),
       token_auth_on: 1,
       token_auth_primary_key: Faker::Internet.password(32),
       token_auth_secure_paths: ["/#{Faker::Internet.domain_word}", "/#{Faker::Internet.domain_word}"],
       token_auth_backup_key: Faker::Internet.password(16)
    }
  end

  def advanced_stream_params
    {
       failover_publishing_location: "rtmp://#{Faker::Internet.domain_name}"
    }
  end

  # TODO http_rule extract to the separate class
  def create_http_rule(**params)
    data = http_rule_params.merge(**params)

    json_response = interface.post("#{route_http_caching_rules}", rule: data)
    attrs_update json_response
  end

  def http_rule_params
    {
       'name' => Faker::Internet.domain_word,
       'conditions' => {
                          '0' => {
                                    'connective' => 'if',
                                    'subject'=> 'country',
                                    'predicate' => 'equals',
                                    'value' => 'UA'
                                 }
                       },
         'actions' => {
                         '0' => {
                                   'act' => 'force edge to never cache'
                                }
                      }
    }
  end

  def remove_http_rule(id)
    interface.delete route_http_caching_rule(id)
  end

  def remove
    interface.delete route_cdn_resource
  end

  def edit(**params)
    interface.put(route_cdn_resource, params)
  end

  def purge(params)
    interface.post(route_purge, purge_paths: params)
  end

  def prefetch(params)
    interface.post(route_prefetch, prefetch_paths: params)
  end

  def suspend_resource
    interface.put(route_suspend)
  end

  def resume_resource
    interface.put(route_resume)
  end

  def waiter(action)
    wait_until(300, 7) do
      interface.get(route_cdn_resource).cdn_resource.status == action.upcase
    end
  end

  def route_cdn_resources
    '/cdn_resources'
  end

  def route_cdn_resource
    "#{route_cdn_resources}/#{id}"
  end

  def route_cdn_resource_advanced
    "#{route_cdn_resource}/advanced"
  end

  def get_advanced
    json_response = interface.get(route_cdn_resource_advanced)
    attrs_update json_response
  end

  def get
    json_response = interface.get(route_cdn_resource)
    attrs_update json_response
  end

  def route_purge
    "#{route_cdn_resources}/#{id}/purge"
  end

  def route_prefetch
    "#{route_cdn_resources}/#{id}/prefetch"
  end

  def route_billing
    "#{route_cdn_resource}/billing"
  end

  def route_advanced_reporting
    "#{route_cdn_resource}/advanced_reporting"
  end

  def route_suspend
    "#{route_cdn_resource}/suspend"
  end

  def route_resume
    "#{route_cdn_resource}/resume"
  end

  def route_instruction
    "#{route_cdn_resource}/instructions"
  end

  def route_cdn_usage_statistics
    '/cdn_usage_statistics'
  end

  def route_streaming_statistics
    "#{route_cdn_resources}/stream_stats"
  end

  def route_bandwidth_statistics
    "#{route_cdn_resources}/bandwidth"
  end

  def route_available_storage_server_locations
    "#{route_cdn_resources}/available_storage_server_locations"
  end

  def route_http_caching_rules
    "#{route_cdn_resource}/http_caching_rules"
  end

  def route_http_caching_rule(id)
    "#{route_http_caching_rules}/#{id}"
  end

  def route_cdn_letsencrypts
    "#{route_cdn_resource}/letsencrypts"
  end
end