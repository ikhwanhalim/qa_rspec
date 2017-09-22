require 'spec_helper'
require './groups/edge_group_actions'
require './groups/billing_plan_actions'
require './groups/cdn_resource_actions'


describe 'Live Streaming with internal pp ->' do
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
    @eg_limit.delete
    @eg_limit_2.delete
    @ega.edge_group.remove_edge_group
    @ega_2.edge_group.remove_edge_group
  end

  let (:cdn_resource) { @cra.cdn_resource }

  context 'create ->' do
    context 'basic ->' do
      context 'positive ->' do
        context 'default ->' do
          it 'is created' do
            cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id], publishing_location: @locations[0])
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

      context 'negative ->' do
        it 'is not created with incorrect hostname' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: 'internal', cdn_hostname: "#{Faker::Internet.domain_name}.*", \
                                                  edge_group_ids: [@ega.edge_group.id], publishing_location: @locations[0])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["CDN hostname Domain Name has incorrect format"]
        end

        it 'is not created with empty hostname' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: 'internal', cdn_hostname: '', edge_group_ids: [@ega.edge_group.id], \
                                                  publishing_location: @locations[0])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["CDN hostname can't be blank"]
        end

        it 'is not created with unexisting EG id ' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [Faker::Number.number(15)])
          expect(@cra.conn.page.code).to eq '404'
          expect(@cra.conn.page.body.errors).to eq ["EdgeGroup not found"]
        end

        it 'is not created with incorrect resource type ' do
          skip 'todo'
          #TODO modify attr_update
          cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: 'internal', resource_type: 'HTTP_PULLII', edge_group_ids: [@ega.edge_group.id], \
                                                  publishing_location: @locations[0])
          expect(@cra.conn.page.code).to eq '403'
          expect(@cra.conn.page.body.errors).to eq ["You do not have permissions for this action"]
        end

        it 'is not created with incorrect publishing_point' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: 'internalllll', edge_group_ids: [@ega.edge_group.id], publishing_location: @locations[0])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred managing the resource remotely, please try again later. Primary publishing location must not be null."]
        end

        it 'is not created with incorrect publishing_location(empty)' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: '', edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred managing the resource remotely, please try again later. Primary publishing location must not be null."]
        end

        it 'is not created with incorrect publishing_location(wrong)' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id], publishing_location: @locations[1])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred managing the resource remotely, please try again later. Publishing location must bound to resource edge groups"]
        end
      end
    end

    context 'advanced ->' do
      context 'positive ->' do
        context 'default ->' do
          it 'is created' do
            cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                    publishing_location: @locations[0], failover_publishing_location: @locations[1])
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

      context 'negative ->' do
        it 'is not created with failover_publishing_location id' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id], \
                                                  publishing_location: @locations[0], failover_publishing_location: @locations[1])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred managing the resource remotely, please try again later. Publishing location must bound to resource edge groups"]
        end

        it 'is not created with secure_wowza_token more than 16 characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                  publishing_location: @locations[0], failover_publishing_location: @locations[1], secure_wowza_token: Faker::Internet.password(20))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred managing the resource remotely, please try again later. Resource secure token length must be <= 16"]
        end

        it 'is not created with empty secure_wowza_token & secure_wowza_on set 1' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                  publishing_location: @locations[0], failover_publishing_location: @locations[1], secure_wowza_token: '')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred managing the resource remotely, please try again later. Resource secure token must not be blank"]
        end

        it 'is not created with token_auth_primary_key more than 32 characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                  publishing_location: @locations[0], failover_publishing_location: @locations[1], token_auth_primary_key: Faker::Internet.password(35))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth primary key is invalid"]
        end

        it 'is not created with token_auth_primary_key less than 6 characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                  publishing_location: @locations[0], failover_publishing_location: @locations[1], token_auth_primary_key: Faker::Internet.password(4))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth primary key is invalid"]
        end

        it 'is not created with token_auth_primary_key contains special characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                  publishing_location: @locations[0], failover_publishing_location: @locations[1], token_auth_primary_key: "#{Faker::Internet.password(20)}%^$#")
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth primary key is invalid"]
        end

        it 'is not created with empty token_auth_primary_key & token_auth_on set 1' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                  publishing_location: @locations[0], failover_publishing_location: @locations[1], token_auth_primary_key: '')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth primary key is invalid", "Token auth primary key can't be blank"]
        end

        it 'is not created with token_auth_backup_key more than 32 characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                  publishing_location: @locations[0], failover_publishing_location: @locations[1], token_auth_backup_key: Faker::Internet.password(35))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth backup key is invalid"]
        end

        it 'is not created with token_auth_backup_key less than 6 characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                  publishing_location: @locations[0], failover_publishing_location: @locations[1], token_auth_backup_key: Faker::Internet.password(4))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth backup key is invalid"]
        end

        it 'is not created with token_auth_backup_key contains special characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                  publishing_location: @locations[0], failover_publishing_location: @locations[1], token_auth_backup_key: "#{Faker::Internet.password(4)}&*^@#")
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth backup key is invalid"]
        end

        it 'is not created with country_access_policy is "ALLOW_BY_DEFAULT"' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                  publishing_location: @locations[0], failover_publishing_location: @locations[1], country_access_policy: 'ALLOW_BY_DEFAULT', countries: ["AL", "GT"])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Country access policy 'ALLOW_BY_DEFAULT' is not included in the list of available policies"]
        end
      end
    end
  end

  context 'edit ->' do
    context 'basic ->' do
      context 'positive ->' do
        before :each do
          @cra.cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                       publishing_location: @locations[0])
        end

        after :each do
          @cra.cdn_resource.remove
        end

        context 'hostname ->' do
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

        context 'edge group publishing_location ->' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {publishing_location: @locations[1]} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get
            expect(cdn_resource.cdn_ssl_certificate_id).to be nil
            expect(cdn_resource.cdn_reference.class).to eq Fixnum
            expect(cdn_resource.edge_groups[-1].edge_group.edge_group_locations[0].edge_group_location.aflexi_location_id).to eq @locations[1]
          end
        end
      end

      context 'negative ->' do
        before :all do
          @cra.cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id], publishing_location: @locations[0])
        end

        after :all do
          @cra.cdn_resource.remove
        end

        it 'is not edited with incorrect hostname' do
          cdn_resource.edit({ cdn_resource: {cdn_hostname: "#{Faker::Internet.domain_name}.."} })
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["CDN hostname Domain Name has incorrect format"]
        end

        it 'is not edited with unexisting EG id' do
          cdn_resource.edit({ cdn_resource: {edge_group_ids: [Faker::Number.number(15)]} })
          expect(@cra.conn.page.code).to eq '404'
          expect(@cra.conn.page.body.errors).to eq ["EdgeGroup not found"]
        end

        it 'is not edited with publishing_location id which is not bound to resource EG' do
          cdn_resource.edit({ cdn_resource: { publishing_location: @locations[1]} })
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred updating the resource - Publishing location must bound to resource edge groups"]
        end

        it 'is not edited with internal pp with incorrect publishing_point' do
          cdn_resource.edit({ cdn_resource: {publishing_point: 'internalllll'} })
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred updating the resource - Unable to parse struct with ResourceChangeSetStructSerializer"]
        end
      end
    end

    context 'advanced ->' do
      context 'positive ->' do
        before :each do
          @cra.cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                       publishing_location: @locations[0], failover_publishing_location: @locations[1])
        end

        after :each do
          @cra.cdn_resource.remove
        end

        context 'failover_publishing_location and publishing_location ->' do
          it 'is edited' do
            cdn_resource.edit({ cdn_resource: {edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], publishing_location: @locations[1], \
                                failover_publishing_location: @locations[0]} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get
            expect(cdn_resource.cdn_ssl_certificate_id).to be nil
            expect(cdn_resource.cdn_reference.class).to eq Fixnum
            expect(cdn_resource.publishing_location).to eq @locations[1]
            expect(cdn_resource.failover_publishing_location).to eq @locations[0]
          end
        end

        context 'county_access_policy ->' do
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
          it 'is set hotlink_policy = BLOCK_BY_DEFAULT' do
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

          it 'set hotlink_policy = NONE' do
            cdn_resource.edit({ cdn_resource: {hotlink_policy: 'NONE'} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.hotlink_policy).to eq 'NONE'
          end
        end

        context 'secura_wowza ->' do
          it 'is set secure_wowza_on to false from true' do
            cdn_resource.edit({ cdn_resource: {secure_wowza_on: '0'} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.secure_wowza_on).to eq false
            expect(cdn_resource.secure_wowza_token).to eq nil
          end

          it 'is set secure_wowza_token' do
            new_token = Faker::Internet.password(16)
            cdn_resource.edit({ cdn_resource: {secure_wowza_on: 1, secure_wowza_token: new_token} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.secure_wowza_token).to eq new_token
          end
        end

        context 'token_auth...' do
          it 'is set token_auth_on to false from true' do
            cdn_resource.edit({ cdn_resource: {token_auth_on: '0'} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.token_auth_on).to eq false
          end

          it 'is set token_auth_primary_key' do
            new_key = Faker::Internet.password(32)
            cdn_resource.edit({ cdn_resource: {token_auth_on: 1, token_auth_primary_key: new_key} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.token_auth_primary_key).to eq new_key
          end

          it 'is set token_auth_backup_key' do
            new_key = Faker::Internet.password(16)
            cdn_resource.edit({ cdn_resource: {token_auth_on: 1, token_auth_backup_key: new_key} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.token_auth_backup_key).to eq new_key
          end

          it 'is set token_auth_secure_path' do
            new_path_1 = "/#{Faker::Internet.domain_word}"
            new_path_2 = "/#{Faker::Internet.domain_word}"
            cdn_resource.edit({ cdn_resource: {token_auth_on: 1, token_auth_primary_key: Faker::Internet.password(32), token_auth_secure_paths: [new_path_1, new_path_2]} })
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
          @cra.cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                       publishing_location: @locations[0], failover_publishing_location: @locations[1])
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

  context 'purge/prefetch/instruction/advanced_reporting/le ->' do
    before :all do
      @cra.cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                   publishing_location: @locations[0], failover_publishing_location: @locations[1])
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
      it 'is gettable' do
        @cra.get(cdn_resource.route_instruction)
        expect(@cra.conn.page.code).to eq '200'
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
      @cra.cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'internal', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                   publishing_location: @locations[0], failover_publishing_location: @locations[1])
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

describe 'Live Streaming with external pp ->' do
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
    @eg_limit.delete
    @eg_limit_2.delete
    @ega.edge_group.remove_edge_group
    @ega_2.edge_group.remove_edge_group
  end

  let (:cdn_resource) { @cra.cdn_resource }

  context 'create ->' do
    context 'basic ->' do
      context 'positive ->' do
        context 'default ->' do
          it 'is created' do
            cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id])
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

      context 'negative ->' do
        it 'is not created with incorrect hostname' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: 'external', cdn_hostname: "#{Faker::Internet.domain_name}.*", \
                                                  edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["CDN hostname Domain Name has incorrect format"]
        end

        it 'is not created with empty hostname' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: 'external', cdn_hostname: '', edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["CDN hostname can't be blank"]
        end

        it 'is not created with unexisting EG id ' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: 'external', edge_group_ids: [Faker::Number.number(15)])
          expect(@cra.conn.page.code).to eq '404'
          expect(@cra.conn.page.body.errors).to eq ["EdgeGroup not found"]
        end

        it 'is not created with incorrect resource type ' do
          skip 'todo'
          #TODO modify attr_update
          cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: 'external', resource_type: 'HTTP_PULLII', edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '403'
          expect(@cra.conn.page.body.errors).to eq ["You do not have permissions for this action"]
        end

        it 'is not created with incorrect publishing_point' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: 'externalllll', edge_group_ids: [@ega.edge_group.id])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred managing the resource remotely, please try again later. Primary publishing location must not be null."]
        end

        it 'is not created with incorrect publishing_location(empty)' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id], publishing_location: '')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred managing the resource remotely, please try again later. Resource primary external publishing point must not be blank"]
        end

        it 'is not created with incorrect publishing_location(wrong)' do
          cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id], publishing_location: "http://#{Faker::Internet.domain_name}.*..")
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred managing the resource remotely, please try again later. Resource primary external publishing point is invalid"]
        end
      end
    end

    context 'advanced ->' do
      context 'positive ->' do
        context 'default ->' do
          it 'is created' do
            cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
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

      context 'negative ->' do
        it 'is not created with failover_publishing_location id' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id], \
                                                  failover_publishing_location: "rtmp://#{Faker::Internet.domain_name}.*..")
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred managing the resource remotely, please try again later. Resource backup external publishing point is invalid"]
        end

        it 'is not created with secure_wowza_token more than 16 characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'external',  edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                  secure_wowza_token: Faker::Internet.password(20))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred managing the resource remotely, please try again later. Resource secure token length must be <= 16"]
        end

        it 'is not created with empty secure_wowza_token & secure_wowza_on set 1' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                  secure_wowza_token: '')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred managing the resource remotely, please try again later. Resource secure token must not be blank"]
        end

        it 'is not created with token_auth_primary_key more than 32 characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id],\
                                                  token_auth_primary_key: Faker::Internet.password(35))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth primary key is invalid"]
        end

        it 'is not created with token_auth_primary_key less than 6 characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                  token_auth_primary_key: Faker::Internet.password(4))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth primary key is invalid"]
        end

        it 'is not created with token_auth_primary_key contains special characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                  token_auth_primary_key: "#{Faker::Internet.password(20)}%^$#")
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth primary key is invalid"]
        end

        it 'is not created with empty token_auth_primary_key & token_auth_on set 1' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                  token_auth_primary_key: '')
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth primary key is invalid", "Token auth primary key can't be blank"]
        end

        it 'is not created with token_auth_backup_key more than 32 characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                  token_auth_backup_key: Faker::Internet.password(35))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth backup key is invalid"]
        end

        it 'is not created with token_auth_backup_key less than 6 characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                  token_auth_backup_key: Faker::Internet.password(4))
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth backup key is invalid"]
        end

        it 'is not created with token_auth_backup_key contains special characters' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                  token_auth_backup_key: "#{Faker::Internet.password(4)}&*^@#")
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Token auth backup key is invalid"]
        end

        it 'is not created with country_access_policy is "ALLOW_BY_DEFAULT"' do
          cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], \
                                                  country_access_policy: 'ALLOW_BY_DEFAULT', countries: ["AL", "GT"])
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["Country access policy 'ALLOW_BY_DEFAULT' is not included in the list of available policies"]
        end
      end
    end
  end

  context 'edit ->' do
    context 'basic ->' do
      context 'positive ->' do
        before :each do
          @cra.cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
        end

        after :each do
          @cra.cdn_resource.remove
        end

        context 'hostname ->' do
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

        context 'edge group publishing_location ->' do
          it 'is edited' do
            new_location = "http://#{Faker::Internet.domain_name}"
            cdn_resource.edit({ cdn_resource: {publishing_location: new_location} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get
            expect(cdn_resource.cdn_ssl_certificate_id).to be nil
            expect(cdn_resource.cdn_reference.class).to eq Fixnum
            expect(cdn_resource.publishing_location).to eq new_location
            expect(cdn_resource.failover_publishing_location).to be nil
          end
        end
      end

      context 'negative ->' do
        before :all do
          @cra.cdn_resource.create_vod_stream_resource(type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id])
        end

        after :all do
          @cra.cdn_resource.remove
        end

        it 'is not edited with incorrect hostname' do
          cdn_resource.edit({ cdn_resource: {cdn_hostname: "#{Faker::Internet.domain_name}.."} })
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["CDN hostname Domain Name has incorrect format"]
        end

        it 'is not edited with unexisting EG id' do
          cdn_resource.edit({ cdn_resource: {edge_group_ids: [Faker::Number.number(15)]} })
          expect(@cra.conn.page.code).to eq '404'
          expect(@cra.conn.page.body.errors).to eq ["EdgeGroup not found"]
        end

        it 'is not edited with publishing_location id which is not bound to resource EG' do
          cdn_resource.edit({ cdn_resource: { publishing_location: "http://#{Faker::Internet.domain_name}.*.."} })
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred updating the resource - Resource primary external publishing point is invalid"]
        end

        it 'is not edited with external pp with incorrect publishing_point' do
          cdn_resource.edit({ cdn_resource: {publishing_point: 'externalllll'} })
          expect(@cra.conn.page.code).to eq '422'
          expect(@cra.conn.page.body.errors).to eq ["An error occurred updating the resource - Primary publishing location must not be null."]
        end
      end
    end

    context 'advanced ->' do
      context 'positive ->' do
        before :each do
          @cra.cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
        end

        after :each do
          @cra.cdn_resource.remove
        end

        context 'failover_publishing_location and publishing_location ->' do
          it 'is edited' do
            new_location, new_failover_location = "http://#{Faker::Internet.domain_name}", "rtmp://#{Faker::Internet.domain_name}"
            cdn_resource.edit({ cdn_resource: {edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], publishing_location: new_location, \
                                               failover_publishing_location: new_failover_location} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get
            expect(cdn_resource.cdn_ssl_certificate_id).to be nil
            expect(cdn_resource.cdn_reference.class).to eq Fixnum
            expect(cdn_resource.publishing_location).to eq new_location
            expect(cdn_resource.failover_publishing_location).to eq new_failover_location
          end

          it 'is remove failover_publishing_location' do
            cdn_resource.edit({ cdn_resource: {edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id], failover_publishing_location: ''} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get
            expect(cdn_resource.cdn_ssl_certificate_id).to be nil
            expect(cdn_resource.cdn_reference.class).to eq Fixnum
            expect(cdn_resource.failover_publishing_location).to be nil
          end
        end

        context 'county_access_policy ->' do
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
          it 'is set hotlink_policy = BLOCK_BY_DEFAULT' do
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

          it 'set hotlink_policy = NONE' do
            cdn_resource.edit({ cdn_resource: {hotlink_policy: 'NONE'} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.hotlink_policy).to eq 'NONE'
          end
        end

        context 'secura_wowza ->' do
          it 'is set secure_wowza_on to false from true' do
            cdn_resource.edit({ cdn_resource: {secure_wowza_on: '0'} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.secure_wowza_on).to eq false
            expect(cdn_resource.secure_wowza_token).to eq nil
          end

          it 'is set secure_wowza_token' do
            new_token = Faker::Internet.password(16)
            cdn_resource.edit({ cdn_resource: {secure_wowza_on: 1, secure_wowza_token: new_token} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.secure_wowza_token).to eq new_token
          end
        end

        context 'token_auth...' do
          it 'is set token_auth_on to false from true' do
            cdn_resource.edit({ cdn_resource: {token_auth_on: '0'} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.token_auth_on).to eq false
          end

          it 'is set token_auth_primary_key' do
            new_key = Faker::Internet.password(32)
            cdn_resource.edit({ cdn_resource: {token_auth_on: 1, token_auth_primary_key: new_key} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.token_auth_primary_key).to eq new_key
          end

          it 'is set token_auth_backup_key' do
            new_key = Faker::Internet.password(16)
            cdn_resource.edit({ cdn_resource: {token_auth_on: 1, token_auth_backup_key: new_key} })
            expect(@cra.conn.page.code).to eq '204'
            cdn_resource.get_advanced
            expect(cdn_resource.token_auth_backup_key).to eq new_key
          end

          it 'is set token_auth_secure_path' do
            new_path_1 = "/#{Faker::Internet.domain_word}"
            new_path_2 = "/#{Faker::Internet.domain_word}"
            cdn_resource.edit({ cdn_resource: {token_auth_on: 1, token_auth_primary_key: Faker::Internet.password(32), \
                                               token_auth_secure_paths: [new_path_1, new_path_2]} })
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
          @cra.cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id])
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

  context 'purge/prefetch/instruction/advanced_reporting/le ->' do
    before :all do
      @cra.cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
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
      @cra.cdn_resource.create_vod_stream_resource(advanced: true, type: 'STREAM_LIVE', point: 'external', edge_group_ids: [@ega.edge_group.id, @ega_2.edge_group.id])
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