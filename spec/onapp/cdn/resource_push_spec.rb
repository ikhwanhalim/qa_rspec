require 'spec_helper'
require './groups/edge_group_actions'
require './groups/billing_plan_actions'
require './groups/cdn_resource_actions'
require './groups/cdn_server_actions'

describe 'HTTP_PUSH ->' do
  # CDN_SERVER, CDN_SERVER_TYPE, IDENTIFIER
  before :all do
    @vma = CdnServerActions.new.precondition
    @vm = @vma.virtual_machine
    @template = @vma.template
    Log.error('ES is not have ACTIVE edge_status') unless @vm.edge_status == 'Active'

    @ss_location = @vm.get_server_location

    # create edge group and add available http locations
    @ega = EdgeGroupActions.new.precondition
    @ega_2 = EdgeGroupActions.new.precondition

    @ega.get(@ega.edge_group.route_edge_group, {available_locations: 'true'})
    @locations = []
    @ega.conn.page.body.edge_group.available_locations.each {|x| @locations <<  x.location.id if x.location.httpSupported}
    Log.error('No available HTTP locations') if @locations.empty?
    Log.error('Not enough HTTP Locations') if @locations.size < 2

    # add locations to the EG
    @ega.edge_group.manipulation_with_locations(@ega.edge_group.route_manipulation('assign'), { location: @locations[0] })
    @ega_2.edge_group.manipulation_with_locations(@ega_2.edge_group.route_manipulation('assign'), { location: @locations[1] })

    # get version of CP
    @cp_version = @ega.version

    # add edge group to billing plan
    @bpa = BillingPlanActions.new.precondition
    @eg_limit = @bpa.billing_plan.create_limit_eg_for_current_bp(@bpa.billing_plan.get_current_bp_id, @ega.edge_group.id)
    @eg_limit_2 = @bpa.billing_plan.create_limit_eg_for_current_bp(@bpa.billing_plan.get_current_bp_id, @ega_2.edge_group.id)

    #create cdn resource
    @cra = CdnResourceActions.new.precondition
    @cr = @cra.cdn_resource
  end

  after :all do
    unless CdnServerActions::IDENTIFIER
      @vma.virtual_machine.destroy
    end

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
            cdn_resource.create_http_resource(type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id])
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
            cdn_resource.create_http_resource(type: 'HTTP_PUSH', cdn_hostname: "#{Faker::Internet.domain_name}.r.worldssl-beta.net", edge_group_ids: [@ega.edge_group.id])
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
            cdn_resource.create_http_resource(type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], cdn_ssl_certificate_id: ssl_cert.id)
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

        context 'lets encrypt' do
          it 'is created' do
            skip 'LE is not supported in CP < v5.6' if @cp_version < 5.6
            cdn_resource.create_http_resource(type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], letsencrypt_ssl_on: 1)
            expect(cdn_resource.id).not_to be nil
            cdn_resource.get
            expect(cdn_resource.letsencrypt_ssl_on).to be true
            @cra.get(cdn_resource.route_cdn_letsencrypts)
            expect(@cra.conn.page.code).to eq '200'
            expect(@cra.conn.page.body.count).to eq 2
          end

          it 'is deleted' do
            skip 'LE is not supported in CP < v5.6' if @cp_version < 5.6
            cdn_resource.remove
            expect(@cra.conn.page.code).to eq '204'
          end

          it 'make sure cdn resource is deleted' do
            skip 'LE is not supported in CP < v5.6' if @cp_version < 5.6
            @cra.get(cdn_resource.route_cdn_resource)
            expect(@cra.conn.page.code).to eq '404'
            expect(@cra.conn.page.body.errors[0]).to eq 'CdnResource not found'
          end
        end
      end

      context 'negative ->' do
        it 'is not created with top level hostname' do
          cdn_resource.create_http_resource(type: 'HTTP_PUSH', cdn_hostname: Faker::Internet.domain_word, edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["CDN hostname Name can not be a top level domain"]
        end

        it 'is not created with incorrect format of hostname' do
          cdn_resource.create_http_resource(type: 'HTTP_PUSH', cdn_hostname: "#{Faker::Internet.domain_name}..", edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["CDN hostname Domain Name has incorrect format"]
        end

        it 'is not created with blank hostname' do
          cdn_resource.create_http_resource(type: 'HTTP_PUSH', cdn_hostname: '', edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["CDN hostname can't be blank"]
        end

        it 'is not created with unexisting EG id' do
          cdn_resource.create_http_resource(type: 'HTTP_PUSH', edge_group_ids: [Faker::Number.number(15)])
          expect(@cra.conn.page.code).to eq '404'
          expect(@cra.conn.page.body.errors).to eq ["EdgeGroup not found"]
        end

        it 'is not created without EG id' do
          cdn_resource.create_http_resource(type: 'HTTP_PUSH', edge_group_ids: [''])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Edge groups can't be blank"]
        end

        it 'is not created with incorrect resource type' do
          skip 'todo modify attr_update'
          #TODO modify attr_update
          cdn_resource.create_http_resource(type: 'HTTP_PUSH', resource_type: 'HTTP_PUSHHHH', edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '403'
          expect(@cra.conn.page.body.errors).to eq ["You do not have permissions for this action"]
        end

        it 'is not created with ftp_password < 6' do
          cdn_resource.create_http_resource(type: 'HTTP_PUSH', ftp_password: Faker::Internet.password(4), edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["FTP password is too short (minimum is 6 characters)"]
        end

        it 'is not created with ftp_password > 32' do
          cdn_resource.create_http_resource(type: 'HTTP_PUSH', ftp_password: Faker::Internet.password(34), edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["FTP password is too long (maximum is 32 characters)"]
        end

        it 'is not created with empty ftp_password' do
          cdn_resource.create_http_resource(type: 'HTTP_PUSH', ftp_password: '', edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors[0]).to eq "FTP password can't be blank"
          expect(@cra.conn.page.body.errors[1]).to eq "FTP password is too short (minimum is 6 characters)"
        end
      end
    end

    context 'advanced ->' do
      context 'positive ->' do
        context 'default' do
          it 'is created' do
            cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], storage_server_location: @ss_location)
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
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], storage_server_location: @ss_location, \
                                            secondary_hostnames: [sec_hostanme, sec_hostanme])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Secondary hostnames hostnames must be unique"]
        end

        it 'is not created with incorrect secondary hostnames' do
          incorrect_sec_hostname = "@sec.#{Faker::Internet.domain_name}"
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], storage_server_location: @ss_location, \
                                            secondary_hostnames: ["sec.#{Faker::Internet.domain_name}", incorrect_sec_hostname])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Secondary hostnames has invalid hostname '#{incorrect_sec_hostname}'"]
        end

        it 'is not created with incorrect ip_addresses' do
          incorrect_ip_address = "0#{Faker::Internet.ip_v4_address}"
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], storage_server_location: @ss_location, \
                                            ip_addresses: "#{Faker::Internet.ip_v4_address},#{incorrect_ip_address}")
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred managing the resource remotely, please try again later. Invalid CIDR IP '#{incorrect_ip_address}/32'"]
        end

        it 'is not created with incorrect domains' do
          incorrect_domain = "0#{Faker::Internet.domain_name}.@@"
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], storage_server_location: @ss_location, \
                                            domains: "#{Faker::Internet.domain_name} #{incorrect_domain}")
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Domains has invalid domain '#{incorrect_domain}'"]
        end

        it 'is not created with url_signing_on set true&url_signing_key set empty' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], storage_server_location: @ss_location,  \
                                            url_signing_on: '1', url_signing_key: nil)
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Url signing key is invalid"]
        end

        it 'is not created with url_signing_on set true&url_signing_key less than 6 letters' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], storage_server_location: @ss_location, \
                                            url_signing_on: '1', url_signing_key: Faker::Internet.password(3,5))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Url signing key is invalid"]
        end

        it 'is not created with url_signing_on set true&url_signing_key more than 32 letters' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], storage_server_location: @ss_location, \
                                            url_signing_on: '1', url_signing_key: Faker::Internet.password(33,40))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Url signing key is invalid"]
        end

        it 'is not created with url_signing_on set true&url_signing_key contains special characters' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], storage_server_location: @ss_location, \
                                            url_signing_on: '1', url_signing_key: "#{Faker::Internet.password(8,12)}%$#@")
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Url signing key is invalid"]
        end

        it 'is not created without limit_rate_after ' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], storage_server_location: @ss_location, \
                                            limit_rate_after: nil)
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Limit rate after can`t be blank if 'Limit rate' field is set"] if @cp_version < 5.6
          expect(@cra.conn.page.body.errors).to eq ["Limit rate after can't be blank if 'Limit rate' field is set"] if @cp_version >= 5.6
        end

        it 'is not created with limit_rate more than 2147483647 KB/s' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], storage_server_location: @ss_location, \
                                            limit_rate: '2147483648')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Limit rate field is invalid"] if @cp_version < 5.6
          expect(@cra.conn.page.body.errors).to eq ["Limit rate is invalid"] if @cp_version >= 5.6
        end

        it 'is not created with limit_rate incorrect value' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], storage_server_location: @ss_location, \
                                            limit_rate: 'kjgjy')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Limit rate field is invalid"] if @cp_version < 5.6
          expect(@cra.conn.page.body.errors).to eq ["Limit rate is invalid"] if @cp_version >= 5.6
        end

        it 'is not created with limit_rate_after value without limit_rate' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], storage_server_location: @ss_location, \
                                            limit_rate: nil)
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Limit rate can`t be blank if 'Limit rate after' field is set"] if @cp_version < 5.6
          expect(@cra.conn.page.body.errors).to eq ["Limit rate can't be blank if 'Limit rate after' field is set"] if @cp_version >= 5.6
        end

        it 'is not created with limit_rate_after more than 2147483647 KB ' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], storage_server_location: @ss_location, \
                                            limit_rate_after: '2147483648')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Limit rate after field is invalid"] if @cp_version < 5.6
          expect(@cra.conn.page.body.errors).to eq ["Limit rate after is invalid"] if @cp_version >= 5.6
        end

        it 'is not created with limit_rate_after incorrect value' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], storage_server_location: @ss_location, \
                                            limit_rate_after: 'nbcv')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Limit rate after field is invalid"] if @cp_version < 5.6
          expect(@cra.conn.page.body.errors).to eq ["Limit rate after is invalid"] if @cp_version >= 5.6
        end

        it 'is not created with duplicate usernames' do
          dubl_user = Faker::Internet.user_name
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], storage_server_location: @ss_location, \
                                            form_pass: {user: [dubl_user, dubl_user], pass: [Faker::Internet.password, Faker::Internet.password]})
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Credential username must be unique"]
        end

        it 'is not created with incorrect usernames' do
          incorrect_user = "7#{Faker::Internet.user_name}1"
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], storage_server_location: @ss_location, \
                                            form_pass: {user: [incorrect_user], pass: [Faker::Internet.password]})
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Credential username field '#{incorrect_user}' is invalid"]
        end

        it 'is not created with username without passwords' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], storage_server_location: @ss_location, \
                                            form_pass: {user: [Faker::Internet.user_name], pass: []})
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Credential password field can`t be empty"] if @cp_version < 5.6
          expect(@cra.conn.page.body.errors).to eq ["Credential password field can't be empty"] if @cp_version >= 5.6
        end

        it 'is not created with password_unauthorized_html more than 1000 characters' do
          cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id], storage_server_location: @ss_location, \
                                            password_unauthorized_html: Faker::Number.number(1003))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Password unauthorized html field is invalid"]
        end
      end
    end
  end

  context 'edit ->'do
    context 'basic ->' do
      context 'positive ->' do
        before :each do
          @cra.cdn_resource.create_http_resource(type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
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
            resource = @cra.get(cdn_resource.route_cdn_resource)
            expect(resource.cdn_resource.ssl_on).to be false
            expect(resource.cdn_resource.cdn_ssl_certificate_id).to eq nil
          end

          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {cdn_ssl_certificate_id: @csa.ssl_cert.id} })
            expect(@cra.conn.page.code).to eq '204'
            resource = @cra.get(cdn_resource.route_cdn_resource)
            expect(resource.cdn_resource.ssl_on).to be false
            expect(resource.cdn_resource.cdn_ssl_certificate_id).to eq @csa.ssl_cert.id
          end
        end

        context 'resource by enabling/disabling letsencrypts ->' do
          it 'is enabled' do
            skip 'LE is not supported in CP < v5.6' if @cp_version < 5.6
            cdn_resource.edit({ cdn_resource: {letsencrypt_ssl_on: 1} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get
            expect(cdn_resource.ssl_on).to be false
            expect(cdn_resource.cdn_ssl_certificate_id).to be nil
            expect(cdn_resource.letsencrypt_ssl_on).to be true
          end

          it 'is disabled' do
            skip 'LE is not supported in CP < v5.6' if @cp_version < 5.6
            cdn_resource.edit({ cdn_resource: {letsencrypt_ssl_on: 0} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get
            expect(cdn_resource.ssl_on).to be false
            expect(cdn_resource.cdn_ssl_certificate_id).to be nil
            expect(cdn_resource.letsencrypt_ssl_on).to be false
          end
        end

        context 'resource hostname ->' do
          it 'is edited' do
            new_hostname = Faker::Internet.domain_name
            cdn_resource.edit({ cdn_resource: {cdn_hostname: new_hostname} })
            expect(@cra.conn.page.code).to eq '204'
            resource = @cra.get(cdn_resource.route_cdn_resource)
            expect(resource.cdn_resource.ssl_on).to be false
            expect(resource.cdn_resource.cdn_hostname).to eq new_hostname
          end
        end

        context 'resource edge group ->' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {edge_group_ids: [@ega.edge_group.id]} })
            expect(@cra.conn.page.code).to eq '204'
            resource = @cra.get(cdn_resource.route_cdn_resource)
            expect(resource.cdn_resource.edge_groups.count).to eq 1
            expect(resource.cdn_resource.edge_groups[0].edge_group.id).to eq @ega.edge_group.id
          end
        end

        context 'ftp password ->' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {edge_group_ids: [@ega.edge_group.id]}, ftp_password: Faker::Internet.password(32) })
            expect(@cra.conn.page.code).to eq '204'
          end
        end
      end

      context 'negative ->' do
        before :all do
          @cra.cdn_resource.create_http_resource(type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
        end

        after :all do
          @cra.cdn_resource.remove
        end

        context 'resource with incorrect hostname ->' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {cdn_hostname: "#{Faker::Internet.domain_name}.."} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["CDN hostname Domain Name has incorrect format"]
          end
        end

        context 'resource edge group (set unexisting EG id) ->' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {edge_group_ids: [Faker::Number.number(15)]} })
            expect(@cra.conn.page.code).to eq '404'
            expect(@cra.conn.page.body.errors).to eq ["EdgeGroup not found"]
          end
        end

        context 'ftp_password < 6 characters ->' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {ftp_password: Faker::Internet.password(4)} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["An error occurred updating the resource - pushOriginPassword must be within the length of 6 to 32 alphanumeric"]
          end
        end

        context 'ftp_password > 32 characters ->' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {ftp_password: Faker::Internet.password(34)} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["An error occurred updating the resource - pushOriginPassword must be within the length of 6 to 32 alphanumeric"]
          end
        end
      end
    end

    context 'advanced ->' do
      context 'positive ->' do
        before :each do
          @cra.cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                 storage_server_location: @ss_location)
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
            cdn_resource.edit({ cdn_resource: {ip_access_policy: 'ALLOW_BY_DEFAULT', ip_addresses: "#{Faker::Internet.ip_v4_address},#{Faker::Internet.ip_v4_address}"} })
            cdn_resource.get_advanced
            expect(cdn_resource.ip_access_policy).to eq 'ALLOW_BY_DEFAULT'
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
      end

      context 'negative ->' do
        before :all do
          @cra.cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                 storage_server_location: @ss_location)
        end

        after :all do
          @cra.cdn_resource.remove
        end

        context 'resource with incorrect secondary hostname' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {cdn_hostname: "#{Faker::Internet.domain_name}.."} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["CDN hostname Domain Name has incorrect format"]
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

        context 'resource limit_rate set incorrect value' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {limit_rate: 'asdas'} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Limit rate field is invalid"] if @cp_version < 5.6
            expect(@cra.conn.page.body.errors).to eq ["Limit rate is invalid"] if @cp_version >= 5.6
          end
        end

        context 'resource limit_rate set more than 2147483647 KB/s' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {limit_rate: 2147483648} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Limit rate field is invalid"] if @cp_version < 5.6
            expect(@cra.conn.page.body.errors).to eq ["Limit rate is invalid"] if @cp_version >= 5.6
          end
        end

        context 'resource limit_rate set 0' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {limit_rate: 0} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Limit rate field is invalid"] if @cp_version < 5.6
            expect(@cra.conn.page.body.errors).to eq ["Limit rate is invalid"] if @cp_version >= 5.6
          end
        end

        context 'resource limit_rate empty' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {limit_rate: ''} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Limit rate can`t be blank if 'Limit rate after' field is set"] if @cp_version < 5.6
            expect(@cra.conn.page.body.errors).to eq ["Limit rate can't be blank if 'Limit rate after' field is set"] if @cp_version >= 5.6
          end
        end

        context 'resource limit_rate_after set incorrect value' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {limit_rate_after: 'jhkl'} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Limit rate after field is invalid"] if @cp_version < 5.6
            expect(@cra.conn.page.body.errors).to eq ["Limit rate after is invalid"] if @cp_version >= 5.6
          end
        end

        context 'resource limit_rate_after set more than 2147483647 KB' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {limit_rate_after: 2147483648} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Limit rate after field is invalid"] if @cp_version < 5.6
            expect(@cra.conn.page.body.errors).to eq ["Limit rate after is invalid"] if @cp_version >= 5.6
          end
        end

        context 'resource limit_rate_after set 0' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {limit_rate_after: 0} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Limit rate after field is invalid"] if @cp_version < 5.6
            expect(@cra.conn.page.body.errors).to eq ["Limit rate after is invalid"] if @cp_version >= 5.6
          end
        end

        context 'resource limit_rate_after empty' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {limit_rate_after: ''} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Limit rate after can`t be blank if 'Limit rate' field is set"] if @cp_version < 5.6
            expect(@cra.conn.page.body.errors).to eq ["Limit rate after can't be blank if 'Limit rate' field is set"] if @cp_version >= 5.6
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
            expect(@cra.conn.page.body.errors).to eq ["Credential password field can`t be empty"] if @cp_version < 5.6
            expect(@cra.conn.page.body.errors).to eq ["Credential password field can't be empty"] if @cp_version >= 5.6
          end
        end

        context 'resource set password_unauthorized_html more than 1000 characters' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {password_unauthorized_html: Faker::Number.number(1005)} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Password unauthorized html field is invalid"]
          end
        end

        context 'url_signing_on true and url_signing_key empty ->' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {url_signing_on: '1', url_signing_key: ''} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["Url signing key is invalid"]
          end
        end
      end
    end
  end

  context 'advanced reporting ->' do
    before :all do
      @cra.cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                             storage_server_location: @ss_location)
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
      @cra.cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                             storage_server_location: @ss_location)
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
      @cra.cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                             storage_server_location: @ss_location)
    end

    after :all do
      @cra.cdn_resource.remove
    end

    it 'is not gettable' do
      @cra.get(cdn_resource.route_instruction)
      expect(@cra.conn.page.code).to eq '422'
      expect(@cra.conn.page.body.errors).to eq ["Instructions are not available via API for this kind of CDN Resource"]
    end
  end

  context 'HTTP Caching Rules ->' do
    before :all do
      @cra.cdn_resource.create_http_resource(advanced: true, type: 'HTTP_PUSH', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                             storage_server_location: @ss_location)
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

describe 'VoD_PUSH ->' do
  # CDN_SERVER, CDN_SERVER_TYPE, IDENTIFIER
  before :all do
    @vma = CdnServerActions.new.precondition
    @vm = @vma.virtual_machine
    @template = @vma.template
    Log.error('ES is not have ACTIVE edge_status') unless @vm.edge_status == 'Active'

    @ss_location = @vm.get_server_location

    # create edge group and add available http locations
    @ega = EdgeGroupActions.new.precondition
    @ega_2 = EdgeGroupActions.new.precondition

    @ega.get(@ega.edge_group.route_edge_group, {available_locations: 'true'})
    @locations = []
    @ega.conn.page.body.edge_group.available_locations.each {|x| @locations <<  x.location.id if x.location.streamSupported}
    Log.error('No available HTTP locations') if @locations.empty?
    Log.error('Not enough HTTP Locations') if @locations.size < 2

    # add locations to the EG
    @ega.edge_group.manipulation_with_locations(@ega.edge_group.route_manipulation('assign'), { location: @locations[0] })
    @ega_2.edge_group.manipulation_with_locations(@ega_2.edge_group.route_manipulation('assign'), { location: @locations[1] })

    # get version of CP
    @cp_version = @ega.version

    # add edge group to billing plan
    @bpa = BillingPlanActions.new.precondition
    @eg_limit = @bpa.billing_plan.create_limit_eg_for_current_bp(@bpa.billing_plan.get_current_bp_id, @ega.edge_group.id)
    @eg_limit_2 = @bpa.billing_plan.create_limit_eg_for_current_bp(@bpa.billing_plan.get_current_bp_id, @ega_2.edge_group.id)

    #create cdn resource
    @cra = CdnResourceActions.new.precondition
    @cr = @cra.cdn_resource
  end

  after :all do
    unless CdnServerActions::IDENTIFIER
      @vma.virtual_machine.destroy
    end

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
          let (:cdn_resource) { @cra.cdn_resource }

          it 'is created' do
            cdn_resource.create_vod_stream_resource(type: 'STREAM_VOD_PUSH', edge_group_ids: [@ega.edge_group.id])
            expect(cdn_resource.id).not_to be nil
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
        let (:cdn_resource) { @cra.cdn_resource }

        it 'is not created with top level cdn_hostname' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_VOD_PUSH', cdn_hostname: Faker::Internet.domain_word, edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["CDN hostname Name can not be a top level domain"]
        end

        it 'is not created with incorrect format of cdn_hostname' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_VOD_PUSH', cdn_hostname: "#{Faker::Internet.domain_name}..", edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["CDN hostname Domain Name has incorrect format"]
        end

        it 'is not created with blank cdn_hostname' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_VOD_PUSH', cdn_hostname: '', edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["CDN hostname can't be blank"]
        end

        it 'is not created with unexisting EG id' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_VOD_PUSH', edge_group_ids: [Faker::Number.number(15)])
          expect(@cra.conn.page.code).to eq '404'
          expect(@cra.conn.page.body.errors).to eq ["EdgeGroup not found"]
        end

        it 'is not created without EG id' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_VOD_PUSH', edge_group_ids: [''])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Edge groups can't be blank"]
        end

        it 'is not created with incorrect resource type' do
          skip 'todo modify attr_update'
          #TODO modify attr_update
          cdn_resource.create_vod_stream_resource(type: 'STREAM_VOD_PUSHHHH', edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '403'
          expect(@cra.conn.page.body.errors).to eq ["You do not have permissions for this action"]
        end

        it 'is not created with ftp_password < 6' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_VOD_PUSH', ftp_password: Faker::Internet.password(4), edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["FTP password is too short (minimum is 6 characters)"]
        end

        it 'is not created with ftp_password > 32' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_VOD_PUSH', ftp_password: Faker::Internet.password(34), edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["FTP password is too long (maximum is 32 characters)"]
        end

        it 'is not created with empty ftp_password' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_VOD_PUSH', ftp_password: '', edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors[0]).to eq "FTP password can't be blank"
          expect(@cra.conn.page.body.errors[1]).to eq "FTP password is too short (minimum is 6 characters)"
        end
      end
    end

    context 'advanced ->' do
      context 'positive ->' do
        context 'default' do
          let (:cdn_resource) { @cra.cdn_resource }

          it 'is created' do
            cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PUSH', edge_group_ids: [@ega.edge_group.id], \
                                                    storage_server_location: @ss_location)
            expect(cdn_resource.id).not_to be nil
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
        let (:cdn_resource) { @cra.cdn_resource }

        it 'is not created with incorrect domains' do
          incorrect_domain = "0#{Faker::Internet.domain_name}.@@"
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PUSH', edge_group_ids: [@ega.edge_group.id], \
                                                  storage_server_location: @ss_location, domains: "#{Faker::Internet.domain_name} #{incorrect_domain}")
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Domains has invalid domain '#{incorrect_domain}'"]
        end

        it 'is not created with secure_wowza_token more than 16' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PUSH', edge_group_ids: [@ega.edge_group.id], \
                                                  secure_wowza_token: Faker::Internet.password(32))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred managing the resource remotely, please try again later. Resource secure token length must be <= 16"]
        end

        it 'is not created with empty secure_wowza_token & secure_wowza_on set 1' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PUSH', edge_group_ids: [@ega.edge_group.id], secure_wowza_token: '')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred managing the resource remotely, please try again later. Resource secure token must not be blank"]
        end

        it 'is not created with token_auth_primary_key more than 32 characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PUSH', edge_group_ids: [@ega.edge_group.id], \
                                                  token_auth_primary_key: Faker::Internet.password(33))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth primary key is invalid"]
        end

        it 'is not created with token_auth_primary_key less than 6 characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PUSH', edge_group_ids: [@ega.edge_group.id], \
                                                  token_auth_primary_key: Faker::Internet.password(4))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth primary key is invalid"]
        end

        it 'is not created with token_auth_primary_key contains special characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PUSH', edge_group_ids: [@ega.edge_group.id], \
                                                  token_auth_primary_key: "#{Faker::Internet.password(16)}%&*^")
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth primary key is invalid"]
        end

        it 'is not created with empty token_auth_primary_key & token_auth_on set 1' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PUSH', edge_group_ids: [@ega.edge_group.id], token_auth_primary_key: '')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth primary key is invalid", "Token auth primary key can't be blank"]
        end

        it 'is not created with token_auth_backup_key more than 32 characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PUSH', edge_group_ids: [@ega.edge_group.id], \
                                                  token_auth_backup_key: Faker::Internet.password(33))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth backup key is invalid"]
        end

        it 'is not created with token_auth_backup_key less than 6 characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PUSH', edge_group_ids: [@ega.edge_group.id], \
                                                  token_auth_backup_key: Faker::Internet.password(4))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth backup key is invalid"]
        end

        it 'is not created with token_auth_backup_key contains special characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PUSH', edge_group_ids: [@ega.edge_group.id], \
                                                  token_auth_backup_key: "#{Faker::Internet.password(14)}&%^!@")
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth backup key is invalid"]
        end

        it 'is not created with hotlink_access_policy  "ALLOW_BY_DEFAULT"' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PUSH', edge_group_ids: [@ega.edge_group.id], hotlink_policy: 'ALLOW_BY_DEFAULT')
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
          @cra.cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PUSH', edge_group_ids: [@ega.edge_group.id])
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

        context 'resource edge group ->' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {edge_group_ids: [@ega.edge_group.id]} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.edge_groups.count).to eq 1
            expect(cdn_resource.edge_groups[0].edge_group.id).to eq @ega.edge_group.id
          end
        end

        context 'ftp password ->' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {edge_group_ids: [@ega.edge_group.id]}, ftp_password: Faker::Internet.password(32) })
            expect(@cra.conn.page.code).to eq '204'
          end
        end
      end

      context 'negative' do
        before :all do
          @cra.cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PUSH', edge_group_ids: [@ega.edge_group.id])
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

        context 'unexisting EG id' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {edge_group_ids: [Faker::Number.number(15)]} })
            expect(@cra.conn.page.code).to eq '404'
            expect(@cra.conn.page.body.errors).to eq ["EdgeGroup not found"]
          end
        end

        context 'ftp_password < 6 characters ->' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {ftp_password: Faker::Internet.password(4)} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["An error occurred updating the resource - pushOriginPassword must be within the length of 6 to 32 alphanumeric"]
          end
        end

        context 'ftp_password > 32 characters ->' do
          it 'is not edited' do
            cdn_resource.edit({ cdn_resource: {ftp_password: Faker::Internet.password(34)} })
            expect(@cra.conn.page.code).to eq '422'
            expect(@cra.conn.page.body.errors).to eq ["An error occurred updating the resource - pushOriginPassword must be within the length of 6 to 32 alphanumeric"]
          end
        end
      end
    end

    context 'advanced ->' do
      context 'positive ->' do
        before :each do
          @cra.cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PUSH', edge_group_ids: [@ega.edge_group.id])
        end

        after :each do
          @cra.cdn_resource.remove
        end

        context 'country_access_policy ->' do
          it 'is set country_access_policy = BLOCK_BY_DEFAULT' do
            cdn_resource.edit({ cdn_resource: { country_access_policy: 'BLOCK_BY_DEFAULT', countries: ["AL", "GT", "CG", "FR"]} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.country_access_policy).to eq 'BLOCK_BY_DEFAULT'
            expect(cdn_resource.countries.count).to eq 4
          end

          it 'is set country_access_policy = NONE' do
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

            it 'is set = NONE' do
              cdn_resource.edit({ cdn_resource: {hotlink_policy: 'NONE'} })
              expect(@cra.conn.page.code).to eq '204'
              cdn_resource.get_advanced
              expect(cdn_resource.hotlink_policy).to eq 'NONE'
            end
          end

        context 'secure_wowza_on ->' do
            it 'is set to false from true' do
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
          @cra.cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PUSH', edge_group_ids: [@ega.edge_group.id])
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

        it 'is not set token_auth_secure_path (incorrect value)' do
          wrong_path = "#asd#/#{Faker::Internet.domain_word}"
          cdn_resource.edit({ cdn_resource: {token_auth_secure_paths: [wrong_path]} })
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth secure paths has invalid values: [\"#{wrong_path}\"]"]
        end
      end
    end
  end

  context 'purge/prefetch/instruction/advanced_reporting/le ->' do
    before :all do
      @cra.cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PUSH', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
    end

    after :all do
      @cra.cdn_resource.remove
    end

    context 'purge ->' do
      it 'path without entry slashes' do
        cdn_resource.purge('home/123.jpeg')
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.error).to eq ["Only HTTP-type can be purged"]  if @cp_version < 5.6
        expect(@cra.conn.page.body.errors).to eq ["Only HTTP-type can be purged"] if @cp_version >= 5.6
      end

      it 'path with entry slashes' do
        cdn_resource.purge('/home/123.jpeg')
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.error).to eq ["Only HTTP-type can be purged"]  if @cp_version < 5.6
        expect(@cra.conn.page.body.errors).to eq ["Only HTTP-type can be purged"] if @cp_version >= 5.6
      end
    end

    context 'prefetch ->' do
      it 'path without entry slashes' do
        cdn_resource.prefetch('home/123.jpeg')
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.error).to eq ["Only HTTP-type can be prefetched"]  if @cp_version < 5.6
        expect(@cra.conn.page.body.errors).to eq ["Only HTTP-type can be prefetched"] if @cp_version >= 5.6
      end

      it 'path with entry slashes' do
        cdn_resource.prefetch('/home/123.jpeg')
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.error).to eq ["Only HTTP-type can be prefetched"]  if @cp_version < 5.6
        expect(@cra.conn.page.body.errors).to eq ["Only HTTP-type can be prefetched"] if @cp_version >= 5.6
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

    context 'LetsEncrypts page ->' do
      it 'is not gettable' do
        skip 'LE is not supported in CP < v5.6' if @cp_version < 5.6
        @cra.get(cdn_resource.route_cdn_letsencrypts)
        expect(@cra.conn.page.code).to eq '422'
        expect(@cra.conn.page.body.errors).to eq ["Let's Encrypt Certificate is available for CDN Resources with HTTP-type only"]
      end
    end
  end

  context 'suspend/unsuspend/billing_statistics ->' do
    before :all do
      @cra.cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_VOD_PUSH', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
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