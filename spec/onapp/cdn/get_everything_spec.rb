require 'spec_helper'
require './groups/edge_group_actions'
require './groups/billing_plan_actions'
require './groups/cdn_resource_actions'


describe 'GET everything ->' do
  before :all do
    @cra = CdnResourceActions.new.precondition
  end

  let (:cdn_resource) { @cra.cdn_resource }

  it 'is get cdn_usage_statistic' do
    @cra.get(cdn_resource.route_cdn_usage_statistics)
    expect(@cra.conn.page.code).to eq '200'
  end

  it 'is get list of cdn_resources' do
    @cra.get(cdn_resource.route_cdn_resources)
    expect(@cra.conn.page.code).to eq '200'
  end

  it 'is get List of CDN Resources only HTTP pull&push' do
    @cra.get(cdn_resource.route_cdn_resources, { type: 'http' })
    expect(@cra.conn.page.code).to eq '200'
  end

  it 'is get List of CDN Resources only Vod pull&push' do
    @cra.get(cdn_resource.route_cdn_resources, { type: 'vod' })
    expect(@cra.conn.page.code).to eq '200'
  end

  it 'is get List of CDN Resources only Streaming internal&external' do
    @cra.get(cdn_resource.route_cdn_resources, { type: 'live_streaming' })
    expect(@cra.conn.page.code).to eq '200'
  end

  it 'is View CDN Resource Streaming Statistics' do
    skip "todo NoMethodError: undefined method `each_pair' for []:Array"
    #TODO NoMethodError: undefined method `each_pair' for []:Array
    @cra.get(cdn_resource.route_streaming_statistics)
    expect(@cra.conn.page.code).to eq '200'
  end

  it 'is View CDN Resource Bandwidth Statistics' do
    @cra.get(cdn_resource.route_bandwidth_statistics)
    expect(@cra.conn.page.code).to eq '200'
  end

  context 'storage locations' do
    it 'is Get List of Available Storage Locations' do
      @cra.get(cdn_resource.route_available_storage_server_locations)
      expect(@cra.conn.page.code).to eq '200'
    end

    it 'is Get List of Available Storage Locations type=streaming&only_active=true' do
      @cra.get(cdn_resource.route_available_storage_server_locations, {type: 'streaming', only_active: 'true' })
      expect(@cra.conn.page.code).to eq '200'
    end

    it 'is Get List of Available Storage Locations type=streaming&only_active=false' do
      @cra.get(cdn_resource.route_available_storage_server_locations, {type: 'streaming', only_active: 'false' })
      expect(@cra.conn.page.code).to eq '200'
    end

    it 'is Get List of Available Storage Locations type=http&only_active=false' do
      @cra.get(cdn_resource.route_available_storage_server_locations, {type: 'http', only_active: 'false' })
      expect(@cra.conn.page.code).to eq '200'
    end

    it 'is Get List of Available Storage Locations type=http&only_active=true' do
      @cra.get(cdn_resource.route_available_storage_server_locations, {type: 'http', only_active: 'true' })
      expect(@cra.conn.page.code).to eq '200'
    end
  end
end