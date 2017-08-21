require 'spec_helper'
require './groups/edge_group_actions'
require './groups/billing_plan_actions'
require './groups/cdn_resource_actions'
require './groups/cdn_ssl_actions'


describe 'HTTP_PULL ->' do
  before :all do
    # create edge group and add available http locations
    @ega = EdgeGroupActions.new.precondition
    @ega_2 = EdgeGroupActions.new.precondition

    @ega.get(@ega.edge_group.route_edge_group, {available_locations: 'true'})
    @locations = []
    @ega.conn.page.body.edge_group.available_locations.each {|x| @locations <<  x.location.id if x.location.httpSupported}
    Log.error('No available HTTP locations') if @locations.empty?
    Log.error('Not enough HTTP Locations') if @locations.size < 2

    # add locations to the EG
    # @locations.each { |location_id| @ega.edge_group.manipulation_with_locations(@ega.edge_group.route_manipulation('assign'), { location: location_id } )}
    @ega.edge_group.manipulation_with_locations(@ega.edge_group.route_manipulation('assign'), { location: @locations[0] })
    @ega_2.edge_group.manipulation_with_locations(@ega_2.edge_group.route_manipulation('assign'), { location: @locations[1] })

    # add edge group to billing plan
    @bpa = BillingPlanActions.new.precondition
    @eg_limit = @bpa.billing_plan.create_limit_eg_for_current_bp(@bpa.billing_plan.get_current_bp_id, @ega.edge_group.id)
    @eg_limit_2 = @bpa.billing_plan.create_limit_eg_for_current_bp(@bpa.billing_plan.get_current_bp_id, @ega_2.edge_group.id)

    #create cdn resource
    @cra = CdnResourceActions.new.precondition
    @cr = @cra.cdn_resource
  end

  after :all do
    @eg_limit.delete
    @eg_limit_2.delete
    @ega.edge_group.remove_edge_group
    @ega_2.edge_group.remove_edge_group
  end

  let (:cdn_resource) { @cra.cdn_resource }

  context 'create ->' do
    context 'basic ->' do
      context 'positive ->'  do
        context 'default' do
          it 'is created' do
            cdn_resource.create_http_resource(type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id])
            expect(cdn_resource.id).not_to be nil
            cdn_resource.get
            expect(cdn_resource.ssl_on).to be false
          end

          it 'is deleted' do
            cdn_resource.remove
            expect(@cra.conn.page.code).to eq '204'
          end

          it 'make sure cdn resource is deleted' do
            @cra.get(cdn_resource.route_cdn_resource)
            expect(@cra.conn.page.code).to eq '404'
            expect(@cra.conn.page.body.errors[0]).to eq 'CdnResource not found'
          end
        end

        context 'ssl_on = true ->' do
          it 'is created' do
            cdn_resource.create_http_resource(type: 'HTTP_PULL', cdn_hostname: "#{Faker::Internet.domain_name}.r.worldssl-beta.net", \
                                              edge_group_ids: [@ega.edge_group.id])
            expect(cdn_resource.id).not_to be nil
            cdn_resource.get
            expect(cdn_resource.ssl_on).to be true
          end

          it 'is deleted' do
            cdn_resource.remove
            expect(@cra.conn.page.code).to eq '204'
          end

          it 'make sure cdn resource is deleted' do
            @cra.get(cdn_resource.route_cdn_resource)
            expect(@cra.conn.page.code).to eq '404'
            expect(@cra.conn.page.body.errors[0]).to eq 'CdnResource not found'
          end
        end

        context 'ssl certificate' do
          before :all do
            @csa = CdnSslActions.new.precondition
            @csa.ssl_cert.create_ssl_certificate
          end

          after :all do
            @csa.ssl_cert.remove_ssl_certificate
          end

          let (:ssl_cert) {@csa.ssl_cert}

          it 'is created' do
            cdn_resource.create_http_resource(type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], cdn_ssl_certificate_id: ssl_cert.id)
            expect(cdn_resource.id).not_to be nil
            cdn_resource.get
            expect(cdn_resource.ssl_on).to be false
            expect(cdn_resource.cdn_ssl_certificate_id).to eq ssl_cert.id
          end

          it 'is Get SSL Certificate details which is bound to cdn resource' do
            ssl_cert.get
            expect(ssl_cert.id).not_to be nil
            expect(ssl_cert.cdn_reference.class).to eq Fixnum
            expect(ssl_cert.cdn_resources[0].cdn_resource.id).to eq cdn_resource.id
          end

          it 'is deleted' do
            cdn_resource.remove
            expect(@cra.conn.page.code).to eq '204'
          end

          it 'make sure cdn resource is deleted' do
            @cra.get(cdn_resource.route_cdn_resource)
            expect(@cra.conn.page.code).to eq '404'
            expect(@cra.conn.page.body.errors[0]).to eq 'CdnResource not found'
          end
        end

        context 'custom port' do
          it 'is created' do
            custom_port = "#{Faker::Internet.ip_v4_address}:#{Faker::Number.between(1025, 65535)}"
            cdn_resource.create_http_resource(type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], origin: custom_port)
            expect(cdn_resource.id).not_to be nil
            cdn_resource.get
            expect(cdn_resource.origins).to eq [custom_port]
          end

          it 'is deleted' do
            cdn_resource.remove
            expect(@cra.conn.page.code).to eq '204'
          end

          it 'make sure cdn resource is deleted' do
            @cra.get(cdn_resource.route_cdn_resource)
            expect(@cra.conn.page.code).to eq '404'
            expect(@cra.conn.page.body.errors[0]).to eq 'CdnResource not found'
          end
        end
      end

      context 'negative ->' do
        it 'is not created with top level hostname' do
          cdn_resource.create_http_resource(type: 'HTTP_PULL', cdn_hostname: Faker::Internet.domain_word, edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["CDN hostname Name can not be a top level domain"]
        end

        it 'is not created with incorrect format of hostname' do
          cdn_resource.create_http_resource(type: 'HTTP_PULL', cdn_hostname: "#{Faker::Internet.domain_name}..", edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["CDN hostname Domain Name has incorrect format"]
        end

        it 'is not created with blank hostname' do
          cdn_resource.create_http_resource(type: 'HTTP_PULL', cdn_hostname: '', edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["CDN hostname can't be blank"]
        end

        it 'is not created with 3 origin(incorrect key)' do
          cdn_resource.create_http_resource(type: 'HTTP_PULL', origin: [Faker::Internet.ip_v4_address, Faker::Internet.ip_v4_address, \
                                            Faker::Internet.ip_v4_address, Faker::Internet.ip_v4_address], edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
        end

        it 'is not created with more than 3 origin' do
          cdn_resource.create_http_resource(type: 'HTTP_PULL', origins: [Faker::Internet.ip_v4_address, Faker::Internet.ip_v4_address, \
                                            Faker::Internet.ip_v4_address, Faker::Internet.ip_v4_address], edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Origins amount is beyond maximum of 3"]
        end

        it 'is not created with 3 origins(hostname)' do
          cdn_resource.create_http_resource(type: 'HTTP_PULL', origins: [Faker::Internet.domain_name, Faker::Internet.domain_name, \
                                            Faker::Internet.domain_name], edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors.count).to eq 3
        end

        it 'is not created with 3 origins(1-st-hostname&2-nd&3-rd-IPs)' do
          cdn_resource.create_http_resource(type: 'HTTP_PULL', origins: [Faker::Internet.ip_v4_address, Faker::Internet.domain_name, \
                                            Faker::Internet.domain_name], edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors.count).to eq 2
        end

        it 'is not created with 2 duplicate origins)' do
          cdn_resource.create_http_resource(type: 'HTTP_PULL', origins: ['23.43.123.45', '23.43.123.45'], edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Origins include duplicated IP"]
        end

        it 'is not created with blank origin' do
          cdn_resource.create_http_resource(type: 'HTTP_PULL', origin: '', edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Origins can't be blank"]
        end

        it 'is not created with unexisting EG id' do
          cdn_resource.create_http_resource(type: 'HTTP_PULL', edge_group_ids: [Faker::Number.number(15)])
          expect(@cra.conn.page.code).to eq '404'
          expect(@cra.conn.page.body.errors).to eq ["EdgeGroup not found"]
        end

        it 'is not created without EG id' do
          cdn_resource.create_http_resource(type: 'HTTP_PULL', edge_group_ids: [''])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Edge groups can't be blank"]
        end

        it 'is not created with incorrect resource type' do
          skip 'todo'
          #TODO modify attr_update
          cdn_resource.create_http_resource(type: 'HTTP_PULL', resource_type: 'HTTP_PULLII', edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '403'
          expect(@cra.conn.page.body.errors).to eq ["You do not have permissions for this action"]
        end

        it 'is not created with custom origin port less than 1024' do
          custom_port = "#{Faker::Internet.ip_v4_address}:#{Faker::Number.between(1, 1024)}"
          cdn_resource.create_http_resource(type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], origin: custom_port)
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Origins include invalid port"]
        end

        it 'is not created with custom origin port more than 65535' do
          custom_port = "#{Faker::Internet.ip_v4_address}:#{Faker::Number.between(65535, 67535)}"
          cdn_resource.create_http_resource(type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], origin: custom_port)
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Origins include invalid port"]
        end

        it 'is not created with custom origin port more than 65535' do
          cdn_resource.create_http_resource(type: 'HTTP_PULL', origins: ["#{Faker::Internet.ip_v4_address}:1025", "#{Faker::Internet.ip_v4_address}:1026", \
                                            "#{Faker::Internet.ip_v4_address}:1027",], edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Origins include different ports", "Origins include different ports"]
        end

        it 'is not created with custom origin port and origin policy "AUTO"' do
          custom_port = "#{Faker::Internet.ip_v4_address}:#{Faker::Number.between(1024, 65535)}"
          cdn_resource.create_http_resource(type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], origin_policy: 'AUTO', origin: custom_port)
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Origins do not allow to use ports"]
        end
      end
    end

    context 'advanced ->' do
      context 'positive ->' do
        context 'default' do
          it 'is created' do
            cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id])
            expect(cdn_resource.id).not_to be nil
            cdn_resource.get
            expect(cdn_resource.ssl_on).to be false
          end

          it 'is deleted' do
            cdn_resource.remove
            expect(@cra.conn.page.code).to eq '204'
          end

          it 'make sure cdn resource is deleted' do
            @cra.get(cdn_resource.route_cdn_resource)
            expect(@cra.conn.page.code).to eq '404'
            expect(@cra.conn.page.body.errors[0]).to eq 'CdnResource not found'
          end
        end

        context 'without origin_policy parameter' do
          it 'is created' do
            cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], origin_policy: '')
            expect(cdn_resource.id).not_to be nil
            cdn_resource.get
            expect(cdn_resource.ssl_on).to be false
          end

          it 'is deleted' do
            cdn_resource.remove
            expect(@cra.conn.page.code).to eq '204'
          end

          it 'make sure cdn resource is deleted' do
            @cra.get(cdn_resource.route_cdn_resource)
            expect(@cra.conn.page.code).to eq '404'
            expect(@cra.conn.page.body.errors[0]).to eq 'CdnResource not found'
          end
        end
      end

      context 'negative ->' do
        it 'is not created with 2 duplicate secondary hostnames' do
          sec_hostanme = Faker::Internet.domain_name
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], \
                                            secondary_hostnames: [sec_hostanme, sec_hostanme])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Secondary hostnames hostnames must be unique"]
        end

        it 'is not created with incorrect secondary hostnames' do
          incorrect_sec_hostname = "@sec.#{Faker::Internet.domain_name}"
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], \
                                            secondary_hostnames: ["sec.#{Faker::Internet.domain_name}", incorrect_sec_hostname])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Secondary hostnames has invalid hostname '#{incorrect_sec_hostname}'"]
        end

        it 'is not created with incorrect ip_addresses' do
          incorrect_ip_address = "0#{Faker::Internet.ip_v4_address}"
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], \
                                            ip_addresses: "#{Faker::Internet.ip_v4_address},#{incorrect_ip_address}")
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred managing the resource remotely, please try again later. Invalid CIDR IP '#{incorrect_ip_address}/32'"]
        end

        it 'is not created with incorrect domains' do
          incorrect_domain = "0#{Faker::Internet.domain_name}.@@"
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], \
                                            domains: "#{Faker::Internet.domain_name} #{incorrect_domain}")
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Domains has invalid domain '#{incorrect_domain}'"]
        end

        it 'is not created with url_signing_on set true&url_signing_key set empty' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], \
                                            url_signing_on: '1', url_signing_key: nil)
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Url signing key is invalid"]
        end

        it 'is not created with url_signing_on set true&url_signing_key less than 6 letters' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], \
                                            url_signing_on: '1', url_signing_key: Faker::Internet.password(3,5))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Url signing key is invalid"]
        end

        it 'is not created with url_signing_on set true&url_signing_key more than 32 letters' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], \
                                            url_signing_on: '1', url_signing_key: Faker::Internet.password(33,40))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Url signing key is invalid"]
        end

        it 'is not created with url_signing_on set true&url_signing_key contains special characters' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], \
                                            url_signing_on: '1', url_signing_key: "#{Faker::Internet.password(8,12)}%$#@")
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Url signing key is invalid"]
        end

        it 'is not created with cache_expiry set 0' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], cache_expiry: '0')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Cache expiry field is invalid"]
        end

        it 'is not created with cache_expiry set 35000001' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], cache_expiry: '35000001')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Cache expiry field is invalid"]
        end

        it 'is not created with proxy_read_time_out set more than 65535' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], proxy_read_time_out: '65536')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Proxy read time out field is invalid"]
        end

        it 'is not created with proxy_read_time_out set incorrect value' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], proxy_read_time_out: 'asdqw')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Proxy read time out field is invalid"]
        end

        it 'is not created with proxy_connect_time_out set more than 75' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], \
                                            proxy_connect_time_out: Faker::Number.between(76, 100))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Proxy connect time out field is invalid"]
        end

        it 'is not created with proxy_connect_time_out set incorrect value' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], proxy_connect_time_out: 'wqerr')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Proxy connect time out field is invalid"]
        end

        it 'is not created with proxy_cache_key set incorrect value' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], proxy_cache_key: 'zvcvb')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Proxy cache key field is invalid"]
        end

        it 'is not created with origin_policy set incorrect value' do  # error
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], origin_policy: 'HTTPPP')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Origin policy 'HTTPPP' is not included in the list of available policies"]
        end

        it 'is not created without limit_rate_after ' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], limit_rate_after: nil)
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Limit rate after can`t be blank if 'Limit rate' field is set"]
        end

        it 'is not created with limit_rate more than 2147483647 KB/s' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], limit_rate: '2147483648')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Limit rate field is invalid"]
        end

        it 'is not created with limit_rate incorrect value' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], limit_rate: 'kjgjy')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Limit rate field is invalid"]
        end

        it 'is not created with limit_rate_after value without limit_rate' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], limit_rate: nil)
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Limit rate can`t be blank if 'Limit rate after' field is set"]
        end

        it 'is not created with limit_rate_after more than 2147483647 KB ' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], limit_rate_after: '2147483648')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Limit rate after field is invalid"]
        end

        it 'is not created with limit_rate_after incorrect value' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], limit_rate_after: 'nbcv')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Limit rate after field is invalid"]
        end

        it 'is not created with duplicate usernames' do
          dubl_user = Faker::Internet.user_name
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id],\
                                           form_pass: {user: [dubl_user, dubl_user],
                                           pass: [Faker::Internet.password, Faker::Internet.password]})
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Credential username must be unique"]
        end

        it 'is not created with incorrect usernames' do
          incorrect_user = "7#{Faker::Internet.user_name}1"
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], \
                                            form_pass: {user: [incorrect_user], pass: [Faker::Internet.password]})
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Credential username field '#{incorrect_user}' is invalid"]
        end

        it 'is not created with username without passwords' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], \
                                            form_pass: {user: [Faker::Internet.user_name], pass: []})
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Credential password field can`t be empty"]
        end

        it 'is not created with password_unauthorized_html more than 1000 characters' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id], \
                                            password_unauthorized_html: Faker::Number.number(1003))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Password unauthorized html field is invalid"]
        end
      end
    end
  end

  context 'edit ->' do
    context 'basic ->' do
      context 'positive ->' do
        before :each do
          @cra.cdn_resource.create_http_resource(type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
        end

        after :each do
          @cra.cdn_resource.remove
        end

        context 'resource by adding ssl certificate ->' do
          before :all do
            @csa = CdnSslActions.new.precondition
          end

          after :all do
            @csa.ssl_cert.remove_ssl_certificate
          end

          it 'is created' do
            expect(cdn_resource.id).not_to be nil
            cdn_resource.get
            expect(cdn_resource.ssl_on).to be false
            expect(cdn_resource.cdn_ssl_certificate_id).to eq nil
          end

          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {cdn_ssl_certificate_id: @csa.ssl_cert.id} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get
            expect(cdn_resource.ssl_on).to be false
            expect(cdn_resource.cdn_ssl_certificate_id).to eq @csa.ssl_cert.id
          end
        end

        context 'resource hostname ->' do
          it 'is edited' do
            new_hostname = Faker::Internet.domain_name
            cdn_resource.edit({ cdn_resource: {cdn_hostname: new_hostname} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get
            expect(cdn_resource.ssl_on).to be false
            expect(cdn_resource.cdn_hostname).to eq new_hostname
          end
        end

        context 'resource edge group ->' do
          it 'resource edge group' do
            cdn_resource.edit({ cdn_resource: {edge_group_ids: [@ega.edge_group.id]} })
            cdn_resource.get
            expect(cdn_resource.edge_groups.count).to eq 1
            expect(cdn_resource.edge_groups[0].edge_group.id).to eq @ega.edge_group.id
          end
        end

        context 'resource origin ->' do
          it 'is edited' do
            new_origin = Faker::Internet.ip_v4_address
            cdn_resource.edit({ cdn_resource: {origin: new_origin} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get
            expect(cdn_resource.ssl_on).to be false
            expect(cdn_resource.origins).to eq [new_origin]
          end
        end

        context 'resource origin custom port ->' do
          it 'is edited' do
            new_origin = "#{Faker::Internet.ip_v4_address}:2342"
            cdn_resource.edit({ cdn_resource: {origin: new_origin} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get
            expect(cdn_resource.ssl_on).to be false
            expect(cdn_resource.origins).to eq [new_origin]
          end
        end

        context 'resource reset origin custom port ->' do
          it 'is set custom port' do
            port = Faker::Number.between(2345, 3456)
            new_origin = cdn_resource.origins[0]
            cdn_resource.edit({ cdn_resource: {origin: "#{new_origin}:#{port}"} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get
            expect(cdn_resource.ssl_on).to be false
            expect(cdn_resource.origins).to eq ["#{new_origin}:#{port}"]
          end

          it 'is reset a custom port ->' do
            resource = @cra.get(cdn_resource.route_cdn_resource)
            new_origin = resource.cdn_resource.origins[0].split(':')[0]
            cdn_resource.edit({ cdn_resource: {origin: new_origin} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get
            expect(cdn_resource.ssl_on).to be false
            expect(cdn_resource.origins).to eq [new_origin]
          end
        end
      end

      context 'negative ->' do
        before :all do
          @cra.cdn_resource.create_http_resource(type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
        end

        after :all do
          @cra.cdn_resource.remove
        end

        context 'resource with incorrect origin custom port' do
          it 'is not edited' do
            port = Faker::Number.between(1, 1024)
            new_origin = "#{Faker::Internet.ip_v4_address}:#{port}"
            cdn_resource.edit({ cdn_resource: {origin: "#{new_origin}"} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Origins include invalid port"]
          end
        end

        context 'resource with incorrect hostname' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {cdn_hostname: "#{Faker::Internet.domain_name}.."} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["CDN hostname Domain Name has incorrect format"]
          end
        end

        context 'resource edge group (set unexisting EG id)' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {edge_group_ids: [Faker::Number.number(15)]} })
            expect(@cra.conn.page.code).to eq '404'
            expect(@cra.conn.page.body.errors).to eq ["EdgeGroup not found"]
          end
        end

        context 'resource origin (set more than 3 origins)' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {origins: [Faker::Internet.ip_v4_address, Faker::Internet.ip_v4_address, \
                                Faker::Internet.ip_v4_address, Faker::Internet.ip_v4_address]} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Origins amount is beyond maximum of 3"]
          end
        end

        context 'resource origin (set 2 duplicate origins)' do
          it 'is not edited' do
            dubl_origin = Faker::Internet.ip_v4_address
            cdn_resource.edit({ cdn_resource: {origins: [dubl_origin, dubl_origin]} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Origins include duplicated IP"]
          end
        end
      end
    end

    context 'advanced ->' do
      context 'positive ->' do
        before :each do
          @cra.cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
        end

        after :each do
          @cra.cdn_resource.remove
        end

        context 'resource secondary hostnames' do
          it 'is edited' do
            new_sec_hostname = "new.sec.#{Faker::Internet.domain_name}"
            cdn_resource.edit({ cdn_resource: {secondary_hostnames: [ new_sec_hostname]} })
            cdn_resource.get
            expect(cdn_resource.secondary_hostnames[0]).to eq new_sec_hostname
          end
        end

        context 'resource remove all secondary hostnames' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {secondary_hostnames: ['']} })
            cdn_resource.get
            expect(cdn_resource.secondary_hostnames.count).to eq 0
          end
        end

        context 'resource ip_access_policy set "NONE"' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {ip_access_policy: 'NONE'} })
            cdn_resource.get_advanced
            expect(cdn_resource.ip_access_policy).to eq 'NONE'
          end
        end

        context 'resource ip_access_policy set "ALLOW_BY_DEFAULT"' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {ip_access_policy: 'ALLOW_BY_DEFAULT', \
                                ip_addresses: "#{Faker::Internet.ip_v4_address},#{Faker::Internet.ip_v4_address}"} })
            cdn_resource.get_advanced
            expect(cdn_resource.ip_access_policy).to eq 'ALLOW_BY_DEFAULT'
          end
        end

        context 'resource country_access_policy set "ALLOW_BY_DEFAULT"' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {country_access_policy: 'ALLOW_BY_DEFAULT', countries: ["CG", "BD", "EG", "FR"]} })
            cdn_resource.get_advanced
            expect(cdn_resource.country_access_policy).to eq 'ALLOW_BY_DEFAULT'
            expect(cdn_resource.countries.count).to eq 4
          end
        end

        context 'resource country_access_policy set "BLOCK_BY_DEFAULT"' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {country_access_policy: 'BLOCK_BY_DEFAULT', countries: ["CG", "BD", "EG", "FR"]} })
            cdn_resource.get_advanced
            expect(cdn_resource.country_access_policy).to eq 'BLOCK_BY_DEFAULT'
            expect(cdn_resource.countries.count).to eq 4
          end
        end

        context 'resource country_access_policy set "NONE"' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {country_access_policy: 'NONE'} })
            cdn_resource.get_advanced
            expect(cdn_resource.country_access_policy).to eq 'NONE'
            # expect(cdn_resource.countries).to eq nil
          end
        end

        context 'resource hotlink_policy set "ALLOW_BY_DEFAULT"' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {hotlink_policy: 'ALLOW_BY_DEFAULT'} })
            cdn_resource.get_advanced
            expect(cdn_resource.hotlink_policy).to eq 'ALLOW_BY_DEFAULT'
          end
        end

        context 'resource hotlink_policy set "BLOCK_BY_DEFAULT"' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {hotlink_policy: 'BLOCK_BY_DEFAULT'} })
            cdn_resource.get_advanced
            expect(cdn_resource.hotlink_policy).to eq 'BLOCK_BY_DEFAULT'
          end
        end

        context 'resource hotlink_policy set "NONE"' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {hotlink_policy: 'NONE'} })
            cdn_resource.get_advanced
            expect(cdn_resource.hotlink_policy).to eq 'NONE'
          end
        end

        context 'resource cache_expiry' do
          it 'is edited' do
            new_cache_expiry = Faker::Number.between(1025, 65535)
            cdn_resource.edit({ cdn_resource: {cache_expiry: new_cache_expiry} })
            cdn_resource.get_advanced
            expect(cdn_resource.cache_expiry).to eq new_cache_expiry
          end
        end

        context 'resource mp4_pseudo_on set from true to false' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {mp4_pseudo_on: 1} })
            cdn_resource.edit({ cdn_resource: {mp4_pseudo_on: 0} })
            cdn_resource.get_advanced
            expect(cdn_resource.mp4_pseudo_on).to be false
          end
        end

        context 'resource mp4_pseudo_on set from false to true' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {mp4_pseudo_on: 1} })
            cdn_resource.get_advanced
            expect(cdn_resource.mp4_pseudo_on).to be true
          end
        end

        context 'resource flv_pseudo_on set from true to false' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {flv_pseudo_on: 0} })
            cdn_resource.get_advanced
            expect(cdn_resource.mp4_pseudo_on).to be false
          end
        end

        context 'resource flv_pseudo_on set from false to true' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {flv_pseudo_on: 0} })
            cdn_resource.edit({ cdn_resource: {flv_pseudo_on: 1} })
            cdn_resource.get_advanced
            expect(cdn_resource.flv_pseudo_on).to be true
          end
        end

        context 'resource ignore_set_cookie_on set from true to false' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {ignore_set_cookie_on: 1} })
            cdn_resource.edit({ cdn_resource: {ignore_set_cookie_on: 0} })
            cdn_resource.get_advanced
            expect(cdn_resource.ignore_set_cookie_on).to be false
          end
        end

        context 'resource ignore_set_cookie_on set from false to true ' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {ignore_set_cookie_on: 1} })
            cdn_resource.get_advanced
            expect(cdn_resource.ignore_set_cookie_on).to be true
          end
        end

        context 'resource http_bot_blocked set from true to false' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {http_bot_blocked: 0} })
            cdn_resource.get_advanced
            expect(cdn_resource.http_bot_blocked).to be false
          end
        end

        context 'resource http_bot_blocked set from false to true' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {http_bot_blocked: 0} })
            cdn_resource.edit({ cdn_resource: {http_bot_blocked: 1} })
            cdn_resource.get_advanced
            expect(cdn_resource.http_bot_blocked).to be true
          end
        end

        context 'resource proxy_read_time_out' do
          it 'is edited' do
            new_timeout = Faker::Number.between(1025, 65535)
            cdn_resource.edit({ cdn_resource: {proxy_read_time_out: new_timeout} })
            cdn_resource.get_advanced
            expect(cdn_resource.proxy_read_time_out).to eq new_timeout
          end
        end

        context 'resource proxy_connect_time_out' do
          it 'is edited' do
            new_timeout = Faker::Number.between(23, 75)
            cdn_resource.edit({ cdn_resource: {proxy_connect_time_out: new_timeout} })
            cdn_resource.get_advanced
            expect(cdn_resource.proxy_connect_time_out).to eq new_timeout
          end
        end

        context 'resource proxy_cache_key set "$host$request_uri"' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {proxy_cache_key: '$host$request_uri'} })
            cdn_resource.get_advanced
            expect(cdn_resource.proxy_cache_key).to eq '$host$request_uri'
          end
        end

        context 'resource proxy_cache_key set "$host$uri"' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {proxy_cache_key: '$host$uri'} })
            cdn_resource.get_advanced
            expect(cdn_resource.proxy_cache_key).to eq '$host$uri'
          end
        end

        context 'resource proxy_cache_key set "$proxy_host$request_uri"' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {proxy_cache_key: '$proxy_host$request_uri'} })
            cdn_resource.get_advanced
            expect(cdn_resource.proxy_cache_key).to eq '$proxy_host$request_uri'
          end
        end

        context 'resource proxy_cache_key set "$proxy_host$uri"' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {proxy_cache_key: '$proxy_host$uri'} })
            cdn_resource.get_advanced
            expect(cdn_resource.proxy_cache_key).to eq '$proxy_host$uri'
          end
        end

        context 'resource origin_policy set HTTPS' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {origin_policy: 'HTTPS'} })
            cdn_resource.get_advanced
            expect(cdn_resource.origin_policy).to eq 'HTTPS'
          end
        end

        context 'resource origin_policy set AUTO' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {origin_policy: 'AUTO'} })
            cdn_resource.get_advanced
            expect(cdn_resource.origin_policy).to eq 'AUTO'
          end
        end

        context 'resource origin_policy set HTTP' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {origin_policy: 'HTTP'} })
            cdn_resource.get_advanced
            expect(cdn_resource.origin_policy).to eq 'HTTP'
          end
        end

        context 'resource limit_rate ' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {limit_rate: 2147483647} })
            cdn_resource.get_advanced
            expect(cdn_resource.limit_rate).to eq 2147483647
          end
        end

        context 'resource limit_rate_after' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {limit_rate_after: 2147483647} })
            cdn_resource.get_advanced
            expect(cdn_resource.limit_rate_after).to eq 2147483647
          end
        end

        context 'resource limit_rate & limit_rate_after' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {limit_rate: 2147483647, limit_rate_after: 2147483647} })
            cdn_resource.get_advanced
            expect(cdn_resource.limit_rate).to eq 2147483647
            expect(cdn_resource.limit_rate_after).to eq 2147483647
          end
        end

        context 'resource User Credentials' do
          it 'is edited' do
            new_user = Faker::Internet.user_name
            new_pass = Faker::Internet.password
            cdn_resource.edit({ cdn_resource: {form_pass: {user: [new_user], pass: [new_pass]}} })
            cdn_resource.get_advanced
            expect(cdn_resource.passwords.keys[0]).to eq new_user
            expect(cdn_resource.passwords.values[0]).to eq new_pass
          end
        end

        context 'resource password_unauthorized_html' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {password_unauthorized_html: 'YOU ARE NOT ALLOWED' } })
            cdn_resource.get_advanced
            expect(cdn_resource.password_unauthorized_html).to eq 'YOU ARE NOT ALLOWED'
          end
        end

        context 'resource password_on set 1' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {password_on: 0 } })
            cdn_resource.edit({ cdn_resource: {password_on: 1 } })
            cdn_resource.get_advanced
            expect(cdn_resource.password_on).to be true
          end
        end

        context 'resource password_on set 0' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {password_on: 0 } })
            cdn_resource.get_advanced
            expect(cdn_resource.password_on).to be false
          end
        end

        context 'resource hls_on set 1' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {hls_on: 1 } })
            cdn_resource.get_advanced
            expect(cdn_resource.hls_on).to be true
          end
        end

        context 'resource hls_on set 0' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {hls_on: 1 } })
            cdn_resource.edit({ cdn_resource: {hls_on: 0 } })
            cdn_resource.get_advanced
            expect(cdn_resource.hls_on).to be false
          end
        end
      end

      context 'negative ->' do
        before :all do
          @cra.cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
        end

        after :all do
          @cra.cdn_resource.remove
        end

        context 'resource with 3 origins and all different custom origin port' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {origins: ["#{Faker::Internet.ip_v4_address}:4567", \
                                "#{Faker::Internet.ip_v4_address}:7654", "#{Faker::Internet.ip_v4_address}:9864"]} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Origins include different ports and Origins include different ports"]
          end
        end

        context 'resource with custom origin port and origin policy "AUTO"' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {origin: "#{Faker::Internet.ip_v4_address}:3243"} })
            cdn_resource.edit({ cdn_resource: {origin_policy: 'AUTO'} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Origins do not allow to use ports"]
            cdn_resource.edit({ cdn_resource: {origin: Faker::Internet.ip_v4_address} })  #return to original
          end
        end

        context 'resource with incorrect secondary hostname' do
          it 'is not edited' do
            incorrect_hostname = "sec.#{Faker::Internet.domain_name}.."
            cdn_resource.edit({ cdn_resource: {secondary_hostnames: [incorrect_hostname]} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Secondary hostname '#{incorrect_hostname}' is not a valid hostname"]
          end
        end

        context 'resource add with 2 duplicate secondary hostnames' do
          it 'is not edited' do
            dubl_hostname = "sec.#{Faker::Internet.domain_name}"
            cdn_resource.edit({ cdn_resource: {secondary_hostnames: [dubl_hostname, dubl_hostname]} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Secondary hostnames hostnames must be unique"]
          end
        end

        context 'resource ip_access_policy set incorrect value' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {ip_access_policy: 'INCORRECT_VALUE'} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["An error occurred updating the resource - If IpAccessPolicy is set to ALLOW_BY_DEFAULT, IpAccess.type must be set to BLOCK. Vice versa"]
          end
        end

        context 'resource (set incorrect ip_addresses)' do
          it 'is not edited' do
            incorrect_ip = "0#{Faker::Internet.ip_v4_address}"
            cdn_resource.edit({ cdn_resource: {ip_access_policy: 'ALLOW_BY_DEFAULT', ip_addresses: "#{incorrect_ip},#{Faker::Internet.ip_v4_address}"} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["An error occurred updating the resource - Invalid CIDR IP '#{incorrect_ip}/32'"]
          end
        end

        context 'resource country_access_policy set incorrect value' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {country_access_policy: 'INCORRECT_VALUE'} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Country access policy 'INCORRECT_VALUE' is not included in the list of available policies"]
          end
        end

        context 'resource hotlink_policy set incorrect value ' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {hotlink_policy: 'INCORRECT_VALUE'} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Hotlink policy 'INCORRECT_VALUE' is not included in the list of available policies"]
          end
        end

        context 'resource (set incorrect domain)' do
          it 'is not edited' do
            incorrect_domains = "#{Faker::Internet.domain_name}.."
            cdn_resource.edit({ cdn_resource: {domains: incorrect_domains} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["An error occurred updating the resource - Domain access host '#{incorrect_domains}' must be a valid domain"]
          end
        end

        context 'resource cache_expiry set 0' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {cache_expiry: 0} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Cache expiry field is invalid"]
          end
        end

        context 'resource cache_expiry set 35000001' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {cache_expiry: 35000001} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Cache expiry field is invalid"]
          end
        end

        context 'resource proxy_read_time_out set more than 65535' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {proxy_read_time_out: 65536} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Proxy read time out field is invalid"]
          end
        end

        context 'resource proxy_read_time_out set incorrect value' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {proxy_read_time_out: 'hhh'} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Proxy read time out field is invalid"]
          end
        end

        context 'resource proxy_connect_time_out set more than 75' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {proxy_connect_time_out: 76} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Proxy connect time out field is invalid"]
          end
        end

        context 'resource proxy_connect_time_out set incorrect value' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {proxy_connect_time_out: 'dfssaf'} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Proxy connect time out field is invalid"]
          end
        end

        context 'resource proxy_cache_key set incorrect value' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {proxy_cache_key: 'lihn'} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Proxy cache key field is invalid"]
          end
        end

        context 'resource origin_policy set incorrect value' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {origin_policy: 'iouy'} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Origin policy 'iouy' is not included in the list of available policies"]
          end
        end

        context 'resource limit_rate set incorrect value' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {limit_rate: 'asdas'} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Limit rate field is invalid"]
          end
        end

        context 'resource limit_rate set more than 2147483647 KB/s' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {limit_rate: 2147483648} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Limit rate field is invalid"]
          end
        end

        context 'resource limit_rate set 0' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {limit_rate: 0} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Limit rate field is invalid"]
          end
        end

        context 'resource limit_rate empty' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {limit_rate: ''} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Limit rate can`t be blank if 'Limit rate after' field is set"]
          end
        end

        context 'resource limit_rate_after set incorrect value' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {limit_rate_after: 'jhkl'} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Limit rate after field is invalid"]
          end
        end

        context 'resource limit_rate_after set more than 2147483647 KB' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {limit_rate_after: 2147483648} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Limit rate after field is invalid"]
          end
        end

        context 'resource limit_rate_after set 0' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {limit_rate_after: 0} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Limit rate after field is invalid"]
          end
        end

        context 'resource limit_rate_after empty' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {limit_rate_after: ''} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Limit rate after can`t be blank if 'Limit rate' field is set"]
          end
        end

        context 'resource set duplicate usernames ' do
          it 'is not edited' do
            new_user = Faker::Internet.user_name
            new_pass = Faker::Internet.password
            cdn_resource.edit({ cdn_resource: {form_pass: {user: [new_user, new_user], pass: [new_pass, new_pass]}} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Credential username must be unique"]
          end
        end

        context 'resource set incorrect usernames' do
          it 'is not edited' do
            incorrect_user = "123#{Faker::Internet.user_name}"
            cdn_resource.edit({ cdn_resource: {form_pass: {user: [incorrect_user], pass: ['123ewdasew']}} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Credential username field '#{incorrect_user}' is invalid"]
          end
        end

        context 'resource set usernames without passwords' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {form_pass: {user: [Faker::Internet.user_name], pass: ['']}} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Credential password field can`t be empty"]
          end
        end

        context 'resource set password_unauthorized_html more than 1000 characters' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {password_unauthorized_html: Faker::Number.number(1005)} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Password unauthorized html field is invalid"]
          end
        end

        context 'resource set url_signing_on true & url_signing_key empty' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {url_signing_on: '1', url_signing_key: ''} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Url signing key is invalid"]
          end
        end
      end
    end
  end

  context 'purge ->' do
    before :all do
      @cra.cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
    end

    after :all do
      @cra.cdn_resource.remove
    end

    it 'path without entry slashes' do
      cdn_resource.purge('home/123.jpeg')
      expect(@cra.conn.page.code).to eq '200'
    end

    it 'path with entry slashes' do
      cdn_resource.purge('/home/123.jpeg')
      expect(@cra.conn.page.code).to eq '200'
    end
  end

  context 'prefetch ->' do
    before :all do
      @cra.cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
    end

    after :all do
      @cra.cdn_resource.remove
    end

    it 'path without entry slashes' do
      cdn_resource.prefetch('home/123.jpeg')
      expect(@cra.conn.page.code).to eq '200'
    end

    it 'path with entry slashes' do
      cdn_resource.prefetch('/home/123.jpeg')
      expect(@cra.conn.page.code).to eq '200'
    end
  end

  context 'billing statistics ->' do
    before :all do
      @cra.cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
    end

    after :all do
      @cra.cdn_resource.remove
    end

    it 'is get billing page' do
      @cra.get(cdn_resource.route_billing)
      expect(@cra.conn.page.code).to eq '200'
    end
  end

  context 'advanced reporting ->' do
    before :all do
      @cra.cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
    end

    after :all do
      @cra.cdn_resource.remove
    end

    it 'is get Advanced Bandwidth Reporting (including Cache utilization)' do
      result = @cra.get(cdn_resource.route_advanced_reporting)
      expect(result.count).to eq 2
      expect(result.bandwidth.count).to eq 3
      expect(result.caching.count).to eq 2
      expect(@cra.conn.page.code).to eq '200'
    end

    it 'is get Advanced Reporting (Status Codes Reporting)' do
      result = @cra.get(cdn_resource.route_advanced_reporting, { stats_type: 'status_codes' })
      expect(result.count).to eq 2
      expect(result.bandwidth.count).to eq 3
      expect(result.caching.count).to eq 2
      expect(@cra.conn.page.code).to eq '200'
    end
  end

  context 'supend/unsuspend ->' do
    before :all do
      @cra.cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
    end

    after :all do
      @cra.cdn_resource.remove
    end

    it 'suspend' do
      cdn_resource.waiter('ACTIVE')
      cdn_resource.suspend_resource
      expect(@cra.conn.page.code).to eq '204'
      cdn_resource.waiter('SUSPENDED')
      cdn_resource.attrs_update
      expect(cdn_resource.status).to eq 'SUSPENDED'
    end

    it 'resume' do
      cdn_resource.resume_resource
      expect(@cra.conn.page.code).to eq '204'
      cdn_resource.waiter('ACTIVE')
      cdn_resource.attrs_update
      expect(cdn_resource.status).to eq 'ACTIVE'
    end
  end

  context 'Get Instruction ->' do
    before :all do
      @cra.cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
    end

    after :all do
      @cra.cdn_resource.remove
    end

    it 'is not gettable' do
      @cra.get(cdn_resource.route_instruction)
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["Instructions are not available for this kind of CDN Resource"]
    end
  end

  context 'HTTP Caching Rules ->' do
    before :all do
      @cra.cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PULL', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
    end

    after :all do
      @cra.cdn_resource.remove
    end

    it 'is create' do
      cdn_resource.create_http_rule
      expect(@cra.conn.page.code).to eq '201'
    end

    it 'is delete' do
      cdn_resource.remove_http_rule(0)
      expect(@cra.conn.page.code).to eq '204'
    end

    it 'is make sure the rule is deleted' do
      skip 'https://onappdev.atlassian.net/browse/CORE-5407'
    end
  end
end

describe 'STREAM_VOD_PULL ->' do
  before :all do
    # create edge group and add available http locations
    @ega = EdgeGroupActions.new.precondition
    @ega_2 = EdgeGroupActions.new.precondition

    @ega.get(@ega.edge_group.route_edge_group, {available_locations: 'true'})
    @locations = []
    @ega.conn.page.body.edge_group.available_locations.each {|x| @locations <<  x.location.id if x.location.streamSupported}
    Log.error('No available HTTP stream locations') if @locations.empty?
    Log.error('Not enough HTTP stream Locations') if @locations.size < 2

    # add locations to the EG
    @ega.edge_group.manipulation_with_locations(@ega.edge_group.route_manipulation('assign'), { location: @locations[0] })
    @ega_2.edge_group.manipulation_with_locations(@ega_2.edge_group.route_manipulation('assign'), { location: @locations[1] })

    # add edge group to billing plan
    @bpa = BillingPlanActions.new.precondition
    @eg_limit = @bpa.billing_plan.create_limit_eg_for_current_bp(@bpa.billing_plan.get_current_bp_id, @ega.edge_group.id)
    @eg_limit_2 = @bpa.billing_plan.create_limit_eg_for_current_bp(@bpa.billing_plan.get_current_bp_id, @ega_2.edge_group.id)

    #create cdn resource
    @cra = CdnResourceActions.new.precondition
    @cr = @cra.cdn_resource
  end

  after :all do
    @eg_limit.delete
    @eg_limit_2.delete
    @ega.edge_group.remove_edge_group
    @ega_2.edge_group.remove_edge_group
  end

  let (:cdn_resource) { @cra.cdn_resource }

  context 'create ->' do
    context 'basic' do
      context 'positive' do
        context 'default' do
          it 'is created' do
            cdn_resource.create_vod_stream_resource(type: 'STREAM_VOD_PULL', edge_group_ids: [@ega.edge_group.id])
            expect(cdn_resource.id).not_to be nil
            resource = @cra.get(cdn_resource.route_cdn_resource)
            expect(resource.cdn_resource.cdn_ssl_certificate_id).to be nil
            expect(resource.cdn_resource.cdn_reference.class).to eq Fixnum
          end

          it 'is deleted' do
            cdn_resource.remove
            expect(@cra.conn.page.code).to eq '204'
          end

          it 'make sure cdn resource is deleted' do
            @cra.get(cdn_resource.route_cdn_resource)
            expect(@cra.conn.page.code).to eq '404'
            expect(@cra.conn.page.body.errors[0]).to eq 'CdnResource not found'
          end
        end
      end

      context 'negative' do
        it 'is not created with incorrect hostname' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_VOD_PULL', cdn_hostname: "#{Faker::Internet.domain_name}..", \
                                                  edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["CDN hostname Domain Name has incorrect format"]
        end

        it 'is not created with empty hostname' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_VOD_PULL', cdn_hostname: '', edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["CDN hostname can't be blank"]
        end

        it 'is not created with more than 1 origin' do
          origin_1 = "#{Faker::Internet.ip_v4_address}"
          origin_2 = "#{Faker::Internet.ip_v4_address}"
          cdn_resource.create_vod_stream_resource(type: 'STREAM_VOD_PULL', origin: [origin_1, origin_2], edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Origins have invalid Ip/hostname for '[\"#{origin_1}\", \"#{origin_2}\"]'"]
        end

        it 'is not created with empty origin ' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_VOD_PULL', origin: '', edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Origins can't be blank"]
        end

        it 'is not created with unexisting EG id ' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_VOD_PULL', edge_group_ids: [Faker::Number.number(15)])
          expect(@cra.conn.page.code).to eq '404'
          expect(@cra.conn.page.body.errors).to eq ["EdgeGroup not found"]
        end

        it 'is not created with incorrect resource type ' do
          skip 'todo'
          #TODO modify attr_update
          cdn_resource.create_vod_stream_resource(type: 'STREAM_VOD_PULL', resource_type: 'HTTP_PULLII', edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '403'
          expect(@cra.conn.page.body.errors).to eq ["You do not have permissions for this action"]
        end
      end
    end

    context 'advanced ->' do
      context 'positive' do
        context 'default' do
          it 'is created' do
            cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PULL', edge_group_ids: [@ega.edge_group.id])
            expect(cdn_resource.id).not_to be nil
            cdn_resource.get
            expect(cdn_resource.cdn_ssl_certificate_id).to be nil
            expect(cdn_resource.cdn_reference.class).to eq Fixnum
          end

          it 'is deleted' do
            cdn_resource.remove
            expect(@cra.conn.page.code).to eq '204'
          end

          it 'make sure cdn resource is deleted' do
            @cra.get(cdn_resource.route_cdn_resource)
            expect(@cra.conn.page.code).to eq '404'
            expect(@cra.conn.page.body.errors[0]).to eq 'CdnResource not found'
          end
        end
      end

      context 'negative' do
        it 'is not created with secure_wowza_token more than 16' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PULL', edge_group_ids: [@ega.edge_group.id], \
                                                  secure_wowza_token: Faker::Internet.password(32))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred managing the resource remotely, please try again later. Resource secure token length must be <= 16"]
        end

        it 'is not created with empty secure_wowza_token & secure_wowza_on set 1' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PULL', edge_group_ids: [@ega.edge_group.id], secure_wowza_token: '')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred managing the resource remotely, please try again later. Resource secure token must not be blank"]
        end

        it 'is not created with token_auth_primary_key more than 32 characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PULL', edge_group_ids: [@ega.edge_group.id], \
                                                  token_auth_primary_key: Faker::Internet.password(33))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth primary key is invalid"]
        end

        it 'is not created with token_auth_primary_key less than 6 characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PULL', edge_group_ids: [@ega.edge_group.id], \
                                                  token_auth_primary_key: Faker::Internet.password(4))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth primary key is invalid"]
        end

        it 'is not created with token_auth_primary_key contains special characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PULL', edge_group_ids: [@ega.edge_group.id], \
                                                  token_auth_primary_key: "#{Faker::Internet.password(16)}%&*^")
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth primary key is invalid"]
        end

        it 'is not created with empty token_auth_primary_key & token_auth_on set 1' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PULL', edge_group_ids: [@ega.edge_group.id], token_auth_primary_key: '')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth primary key is invalid", "Token auth primary key can't be blank"]
        end

        it 'is not created with token_auth_backup_key more than 32 characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PULL', edge_group_ids: [@ega.edge_group.id], \
                                                  token_auth_backup_key: Faker::Internet.password(33))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth backup key is invalid"]
        end

        it 'is not created with token_auth_backup_key less than 6 characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PULL', edge_group_ids: [@ega.edge_group.id], \
                                                  token_auth_backup_key: Faker::Internet.password(4))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth backup key is invalid"]
        end

        it 'is not created with token_auth_backup_key contains special characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PULL', edge_group_ids: [@ega.edge_group.id], \
                                                  token_auth_backup_key: "#{Faker::Internet.password(14)}&%^!@")
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth backup key is invalid"]
        end

        it 'is not created with hotlink_access_policy  "ALLOW_BY_DEFAULT"' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PULL', edge_group_ids: [@ega.edge_group.id], \
                                                  hotlink_policy: 'ALLOW_BY_DEFAULT')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Hotlink policy 'ALLOW_BY_DEFAULT' is not included in the list of available policies"]
        end
      end
    end
  end

  context 'edit ->' do
    context 'basic ->' do
      context 'positive' do
        before :each do
          @cra.cdn_resource.create_vod_stream_resource(type: 'STREAM_VOD_PULL', edge_group_ids: [@ega.edge_group.id])
        end

        after :each do
          @cra.cdn_resource.remove
        end

        context 'hostname' do
          it 'is edited' do
            new_hostname = Faker::Internet.domain_name
            cdn_resource.edit({ cdn_resource: {cdn_hostname: new_hostname} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get
            expect(cdn_resource.cdn_ssl_certificate_id).to be nil
            expect(cdn_resource.cdn_reference.class).to eq Fixnum
            expect(cdn_resource.cdn_hostname).to eq new_hostname
          end
        end

        context 'origin' do
          it 'is edited' do
            new_origin = Faker::Internet.ip_v4_address
            cdn_resource.edit({ cdn_resource: {origin: new_origin} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get
            expect(cdn_resource.cdn_ssl_certificate_id).to be nil
            expect(cdn_resource.cdn_reference.class).to eq Fixnum
            expect(cdn_resource.origins[0]).to eq new_origin
          end
        end
      end

      context 'negative' do
        before :all do
          @cra.cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PULL', edge_group_ids: [@ega.edge_group.id])
        end

        after :all do
          @cra.cdn_resource.remove
        end

        context 'hostname' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {cdn_hostname: "#{Faker::Internet.domain_name}.."} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["CDN hostname Domain Name has incorrect format"]
          end
        end

        context 'origin' do
          it 'is not edited' do
            wrong_origin = "4#{Faker::Internet.ip_v4_address}432"
            cdn_resource.edit({ cdn_resource: {origin: wrong_origin} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Origins have invalid Ip/hostname for '#{wrong_origin}'"]
          end
        end

        context 'unexisting EG id' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {edge_group_ids: [Faker::Number.number(15)]} })
            expect(@cra.conn.page.code).to eq '404'
            expect(@cra.conn.page.body.errors).to eq ["EdgeGroup not found"]
          end
        end
      end
    end

    context 'advanced ->' do
      context 'positive ->' do
        before :each do
          @cra.cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PULL', edge_group_ids: [@ega.edge_group.id])
        end

        after :each do
          @cra.cdn_resource.remove
        end

        context 'country_access_policy ->' do
          it 'is set BLOCK_BY_DEFAULT' do
            cdn_resource.edit({ cdn_resource: { country_access_policy: 'BLOCK_BY_DEFAULT', countries: ["AL", "GT", "CG", "FR"]} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.country_access_policy).to eq 'BLOCK_BY_DEFAULT'
            expect(cdn_resource.countries.count).to eq 4
          end

          it 'is set NONE' do
            cdn_resource.edit({ cdn_resource: {country_access_policy: 'NONE'} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.country_access_policy).to eq 'NONE'
          end
        end

        context 'hotlink_policy ->' do
          it 'is set BLOCK_BY_DEFAULT' do
            cdn_resource.get_advanced
            secondary_hostanme = cdn_resource.domains.split(' ').select { |domain| domain.start_with?('sec.')}.join(' ')
            secondary_hostanme
            cdn_resource.edit({ cdn_resource: { hotlink_policy: 'NONE'} })
            new_domains = "#{Faker::Internet.domain_name} #{Faker::Internet.domain_name}"
            cdn_resource.edit({ cdn_resource: { hotlink_policy: 'BLOCK_BY_DEFAULT', domains: new_domains} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.hotlink_policy).to eq 'BLOCK_BY_DEFAULT'
            expect(cdn_resource.domains.size).to eq new_domains.size + cdn_resource.cdn_hostname.size + secondary_hostanme.size + 1
          end

          it 'is set NONE' do
            cdn_resource.edit({ cdn_resource: {hotlink_policy: 'NONE'} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.hotlink_policy).to eq 'NONE'
            # expect(cdn_resource.domains).to eq nil
          end
        end

        context 'secura_wowza_... ->' do
          it 'is set secure_wowza_on to false from true' do
            cdn_resource.edit({ cdn_resource: {secure_wowza_on: '0'} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.secure_wowza_on).to eq false
            expect(cdn_resource.secure_wowza_token).to eq nil
          end

          it 'is set secure_wowza_token' do
            new_token = Faker::Internet.password(16)
            cdn_resource.edit({ cdn_resource: {secure_wowza_token: new_token} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.secure_wowza_token).to eq new_token
          end
        end

        context 'token_auth_... ->' do
          it 'is set token_auth_on to false from true' do
            cdn_resource.edit({ cdn_resource: {token_auth_on: '0'} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.token_auth_on).to eq false
          end

          it 'is set token_auth_primary_key' do
            new_key = Faker::Internet.password(32)
            cdn_resource.edit({ cdn_resource: {token_auth_primary_key: new_key} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.token_auth_primary_key).to eq new_key
          end

          it 'is set token_auth_backup_key' do
            new_key = Faker::Internet.password(16)
            cdn_resource.edit({ cdn_resource: {token_auth_backup_key: new_key} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.token_auth_backup_key).to eq new_key
          end

          it 'is set token_auth_secure_path' do
            new_path_1 = "/#{Faker::Internet.domain_word}"
            new_path_2 = "/#{Faker::Internet.domain_word}"
            cdn_resource.edit({ cdn_resource: {token_auth_secure_paths: [new_path_1, new_path_2]} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.token_auth_secure_paths.count).to eq 2
            expect(cdn_resource.token_auth_secure_paths.include?(new_path_1)).to eq true
            expect(cdn_resource.token_auth_secure_paths.include?(new_path_2)).to eq true
          end
        end
      end

      context 'negative ->' do
        before :all do
          @cra.cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PULL', edge_group_ids: [@ega.edge_group.id])
        end

        after :all do
          @cra.cdn_resource.remove
        end

        it 'is not set country_access_policy ALLOW_BY_DEFAULT' do
          cdn_resource.edit({ cdn_resource: {country_access_policy: 'ALLOW_BY_DEFAULT', countries: ["AL", "GT", "CG", "FR"]} })
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Country access policy 'ALLOW_BY_DEFAULT' is not included in the list of available policies"]
        end

        it 'is not set country_access_policy INCORRECT_VALUE' do
          cdn_resource.edit({ cdn_resource: {country_access_policy: 'INCORRECT_VALUE'} })
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Country access policy 'INCORRECT_VALUE' is not included in the list of available policies"]
        end

        it 'is not set hotlink_policy INCORRECT_VALUE' do
          cdn_resource.edit({ cdn_resource: {hotlink_policy: 'INCORRECT_VALUE'} })
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Hotlink policy 'INCORRECT_VALUE' is not included in the list of available policies"]
        end

        it 'is not set secure_wowza_on to true and secure_wowza_token empty' do
          cdn_resource.edit({ cdn_resource: {secure_wowza_on: 1, secure_wowza_token: ''} })
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred updating the resource - Resource secure token must not be blank"]
        end

        it 'is not set secure_wowza_token more than 16 characters' do
          cdn_resource.edit({ cdn_resource: {secure_wowza_token: Faker::Internet.password(20)} })
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred updating the resource - Resource secure token length must be <= 16"]
        end

        it 'is not set token_auth_primary_key less than 6' do
          cdn_resource.edit({ cdn_resource: {token_auth_primary_key: Faker::Internet.password(4)} })
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth primary key is invalid"]
        end

        it 'is not set token_auth_primary_key more than 32' do
          cdn_resource.edit({ cdn_resource: {token_auth_primary_key: Faker::Internet.password(35)} })
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth primary key is invalid"]
        end

        it 'is not set token_auth_primary_key contains special characters' do
          cdn_resource.edit({ cdn_resource: {secure_wowza_token: "#{Faker::Internet.password(20)}*&^%"} })
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred updating the resource - Resource secure token length must be <= 16"]
        end

        it 'is not set token_auth_backup_key less than 6' do
          cdn_resource.edit({ cdn_resource: {token_auth_backup_key: Faker::Internet.password(4)} })
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth backup key is invalid"]
        end

        it 'is not set token_auth_backup_key more than 32' do
          cdn_resource.edit({ cdn_resource: {token_auth_backup_key: Faker::Internet.password(35)} })
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth backup key is invalid"]
        end

        it 'is not set token_auth_backup_key contains special characters' do
          cdn_resource.edit({ cdn_resource: {token_auth_backup_key: "#{Faker::Internet.password(20)}*&^%"} })
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth backup key is invalid"]
        end

        it 'is not set  token_auth_secure_path (incorrect value)' do
          wrong_path = "#asd#/#{Faker::Internet.domain_word}"
          cdn_resource.edit({ cdn_resource: {token_auth_secure_paths: [wrong_path]} })
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth secure paths has invalid values: [\"#{wrong_path}\"]"]
        end
      end
    end
  end

  context 'purge/prefetch/instruction/advanced_reporting ->' do
    before :all do
      @cra.cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PULL', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
    end

    after :all do
      @cra.cdn_resource.remove
    end

    context 'purge ->' do
      it 'path without entry slashes' do
        cdn_resource.purge('home/123.jpeg')
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.error).to eq 'Only HTTP-type can be purged'
      end

      it 'path with entry slashes' do
        cdn_resource.purge('/home/123.jpeg')
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.error).to eq 'Only HTTP-type can be purged'
      end
    end

    context 'prefetch ->' do
      it 'path without entry slashes' do
        cdn_resource.prefetch('home/123.jpeg')
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.error).to eq 'Only HTTP-type can be prefetched'
      end

      it 'path with entry slashes' do
        cdn_resource.prefetch('/home/123.jpeg')
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.error).to eq 'Only HTTP-type can be prefetched'
      end
    end

    context 'instruction ->' do
      it 'is not gettable' do
        @cra.get(cdn_resource.route_instruction)
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Instructions are not available via API for this kind of CDN Resource"]
      end
    end

    context 'advanced_reporting ->' do
      it 'is not gettable Advanced Bandwidth Reporting (including Cache utilization)' do
        @cra.get(cdn_resource.route_advanced_reporting)
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Advanced Reporting is not available for Streaming Cdn Resources"]
      end

      it 'is get Advanced Reporting (Status Codes Reporting)' do
        @cra.get(cdn_resource.route_advanced_reporting, { stats_type: 'status_codes' })
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Advanced Reporting is not available for Streaming Cdn Resources"]
      end
    end
  end

  context 'suspend/unsuspend/billing_statistics ->' do
    before :all do
      @cra.cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PULL', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
    end

    after :all do
      @cra.cdn_resource.remove
    end

    it 'suspend' do
      cdn_resource.waiter('ACTIVE')
      cdn_resource.suspend_resource
      expect(@cra.conn.page.code).to eq '204'
      cdn_resource.waiter('SUSPENDED')
      cdn_resource.attrs_update
      expect(cdn_resource.status).to eq 'SUSPENDED'
    end

    it 'resume' do
      cdn_resource.resume_resource
      expect(@cra.conn.page.code).to eq '204'
      cdn_resource.waiter('ACTIVE')
      cdn_resource.attrs_update
      expect(cdn_resource.status).to eq 'ACTIVE'
    end

    it 'is get billing statistics page' do
      @cra.get(cdn_resource.route_billing)
      expect(@cra.conn.page.code).to eq '200'
    end
  end
end