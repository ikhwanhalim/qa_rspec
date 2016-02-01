require 'spec_helper'

describe "Zone has been subscribed" do
  before :all do
    @federation = Federation.new
    @federation.supplier.add_to_federation
    @federation.market.set_preflight
    @federation.trader.zone_appeared?(@federation.market.federation_id)
    @federation.trader.subscribe(@federation.market.federation_id)
  end

  after :all do
    @federation.trader.unsubscribe_all
    @federation.supplier.remove_from_federation
  end

  let(:federation_id) { trader.subscribed_zone.federation_id }
  let(:federation) { @federation }
  let(:supplier) { @federation.supplier }
  let(:trader) { @federation.trader }

  describe "Supplier" do
    it "should be able create announcement" do
      id = supplier.generate_announcement.announcement.id
      announcement = supplier.wait_announcement_id(id)
      expect(announcement.announcement.federation_id).to include federation_id
    end

    it "should be able remove announcement" do
      id = supplier.generate_announcement.announcement.id
      market_id = supplier.wait_announcement_id(id).announcement.federation_id
      announcement = trader.find_announcement(market_id)
      expect(trader.all_announcements).to include announcement
      supplier.remove_announcement(id)
      expect(trader.announcement_removed?(announcement)).to be true
    end
  end

  describe "Trader" do
    after :all do
      @federation.supplier.hypervisors_attach
    end

    it "zone should be present" do
      expect(trader.subscribed_zone).to be_present
    end

    it "should be able subscribe to zone" do
      expect(federation_id).to eq supplier.published_zone.federation_id
    end

    it "should not be able subscribe to zone twice" do
      trader.subscribe(federation_id)
      expect(trader.conn.page.code).to eq "422"
    end

    it "should has virtual template group" do
      tg_labels = trader.get_all('/template_store').map &:label
      expect(tg_labels).to include federation_id
    end

    it "should has virtual data store and data store zone" do
      dsz_labels = trader.get_all('/settings/data_store_zones').map {|dsz| dsz.data_store_group.label}
      ds_labels = trader.get_all('/settings/data_stores').map {|ds| ds.data_store.label}
      expect(dsz_labels).to include federation_id
      expect(ds_labels).to include federation_id
    end

    it "should has virtual network and network zone" do
      ntz_labels = trader.get_all('/settings/network_zones').map {|ntz| ntz.network_group.label}
      nt_labels = trader.get_all('/settings/networks').map {|nt| nt.network.label}
      expect(ntz_labels).to include federation_id
      expect(nt_labels).to include federation_id
    end

    it "should has virtual hypervisor" do
      hv_labels = trader.get_all('/settings/hypervisors').map {|hv| hv.hypervisor.label}
      expect(hv_labels).to include federation_id
    end

    it "error should appeared if no enough resources on supplier" do
      skip('Some VMs were created at HV') unless supplier.hypervisors_detach
      error = trader.create_vm(supplier.template.label)
      expect(error.hypervisor_id.include?("can't be blank")).to be true
      expect(supplier.hypervisors_attach).to be true
    end

    it 'should not be able remove federated template' do
      skip('Was broken in 4.1') if supplier.version < 4.2 || trader.version < 4.2
      template = trader.find_template(supplier.template.label)
      trader.delete("/templates/#{template.id}")
      expect(trader.conn.page.code).to eq "422"
    end

    it 'should not be able remove federated template from template group' do
      err = trader.delete("/settings/image_template_groups/%s/relation_group_templates/%s" %
                              [trader.template_store.id,
                               trader.template_store.relations.first.id]
      ).body
      expect(trader.conn.page.code).to eq "422"
      expect(err.to_s).to include "can't be added or deleted"
    end

    it 'should be able edit annoucement' do
      id = supplier.generate_announcement.announcement.id
      market_id = supplier.wait_announcement_id(id).announcement.federation_id
      announcement_id = trader.find_announcement(market_id).announcement.id
      trader.edit_announcement(announcement_id, 'modified')
      expect(trader.find_announcement(market_id).announcement.text).to eq 'modified'
    end
  end

  describe 'Perform on the market' do
    it 'template tracker sync' do
      skip
    end

    it 'resources sync' do
      skip
    end
  end
end