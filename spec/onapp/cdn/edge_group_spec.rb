require 'spec_helper'
require './groups/edge_group_actions'
require './groups/billing_plan_actions'
require './spec/onapp/cdn/constants_cdn'


describe 'EdgeGroup' do

  context 'Create' do
    before(:all) do
      @ega = EdgeGroupActions.new.precondition
    end

    let (:edge_group) { @ega.edge_group }

    it 'should be created' do
      expect(edge_group.id).not_to be nil
    end

    it 'should be deleted' do
      edge_group.remove_edge_group
      expect(@ega.conn.page.code).to eq '204'
    end

    it 'should make sure CDN Edge Group is deleted' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.code).to eq '404'
    end
  end

  context 'Get Details' do
    before(:all) do
      @ega = EdgeGroupActions.new.precondition
    end

    let (:edge_group) { @ega.edge_group }

    it 'should be created' do
      expect(edge_group.id).not_to be nil
    end

    it 'should Get CDN Edge Group Details' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.code).to eq '200'
      expect(@ega.conn.page.body.edge_group.assigned_locations.count).to eq 0
    end

    it 'should Get Available locations' do
      @ega.get(edge_group.route_edge_group, {available_locations: 'true'})
      expect(@ega.conn.page.body.edge_group.available_locations.count).to be > 3
    end

    it 'should be deleted' do
      edge_group.remove_edge_group
      expect(@ega.conn.page.code).to eq '204'
    end

    it 'should make sure CDN Edge Group is deleted' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.code).to eq '404'
    end
  end

  context 'Edit' do
    before(:all) do
      @ega = EdgeGroupActions.new.precondition
    end

    let (:edge_group) { @ega.edge_group }

    it 'should be created' do
      expect(edge_group.id).not_to be nil
    end

    it 'should be editable Edge Group' do
      edge_group.edit({edge_group: {label: ConstantsCdn::EG_LABEL_EDITED}})
      expect(@ega.conn.page.code).to eq '204'
    end

    it 'make sure Edge Group is edited' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.body.edge_group.label).to eq ConstantsCdn::EG_LABEL_EDITED
      expect(@ega.conn.page.body.edge_group.assigned_locations.count).to eq 0
    end

    it 'should be deleted' do
      edge_group.remove_edge_group
      expect(@ega.conn.page.code).to eq '204'
    end

    it 'should make sure CDN Edge Group is deleted' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.code).to eq '404'
    end
  end

  context 'Assign available location' do
    before(:all) do
      @ega = EdgeGroupActions.new.precondition
      @ega.get(@ega.edge_group.route_edge_group, {available_locations: 'true'})
      @locations = []
      @ega.conn.page.body.edge_group.available_locations.each {|x| @locations << x.location.id}
    end

    let (:edge_group) { @ega.edge_group }

    it 'should be created' do
      expect(edge_group.id).not_to be nil
    end

    it 'should assign location' do
      edge_group.manipulation_with_locations(edge_group.route_manipulation('assign'), { location: @locations[0] })
      expect(@ega.conn.page.body.message).to eq 'Location was successfully assigned'
    end

    it 'should make sure location are assigned' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.body.edge_group.assigned_locations.count).to eq 1
      expect(@ega.conn.page.body.edge_group.assigned_locations[0].location.id).to eq @locations[0]
    end

    it 'should be deleted' do
      edge_group.remove_edge_group
      expect(@ega.conn.page.code).to eq '204'
    end

    it 'should make sure CDN Edge Group is deleted' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.code).to eq '404'
    end
  end

  context 'Unassign location' do
    before(:all) do
      @ega = EdgeGroupActions.new.precondition
      @ega.get(@ega.edge_group.route_edge_group, {available_locations: 'true'})
      @locations = []
      @ega.conn.page.body.edge_group.available_locations.each {|x| @locations << x.location.id}
    end

    let (:edge_group) { @ega.edge_group }

    it 'should be created' do
      expect(edge_group.id).not_to be nil
    end

    it 'should assign location' do
      edge_group.manipulation_with_locations(edge_group.route_manipulation('assign'), { location: @locations[0] })
      edge_group.manipulation_with_locations(edge_group.route_manipulation('assign'), { location: @locations[1] })
      expect(@ega.conn.page.body.message).to eq 'Location was successfully assigned'
    end

    it 'should make sure locations are assigned' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.body.edge_group.assigned_locations.count).to eq 2
      check_locations = []
      @ega.conn.page.body.edge_group.assigned_locations.each {|x| check_locations << x.location.id}
      expect(check_locations).to include @locations[0]
      expect(check_locations).to include @locations[1]
    end

    it 'should unassign location' do
      edge_group.manipulation_with_locations(edge_group.route_manipulation('unassign'),{ location: @locations[0] })
      expect(@ega.conn.page.body.message).to eq 'Location was successfully unassigned'
    end

    it 'should make sure location is unassigned' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.body.edge_group.assigned_locations.count).to eq 1
      check_locations = []
      @ega.conn.page.body.edge_group.assigned_locations.each {|x| check_locations << x.location.id}
      expect(check_locations).not_to include @locations[0]
      expect(check_locations).to include @locations[1]
    end

    it 'should be deleted' do
      edge_group.remove_edge_group
      expect(@ega.conn.page.code).to eq '204'
    end

    it 'should make sure CDN Edge Group is deleted' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.code).to eq '404'
    end
  end

  context 'Modify' do
    before(:all) do
      @ega = EdgeGroupActions.new.precondition
      @ega.get(@ega.edge_group.route_edge_group, {available_locations: 'true'})
      @locations = []
      @ega.conn.page.body.edge_group.available_locations.each {|x| @locations << x.location.id}
    end

    let (:edge_group) { @ega.edge_group }

    it 'should be created' do
      expect(edge_group.id).not_to be nil
    end

    it 'should modify Edge Group' do
      edge_group.manipulation_with_locations(edge_group.route_manipulation('modify'), { locations: [@locations[1],\
                                                                                                    @locations[2]] })
      expect(@ega.conn.page.body.message).to eq "Edge Group was successfully modified."
      expect(@ega.conn.page.body.ids).to eq [@locations[1],@locations[2]]
    end

    it 'should make sure locations are modified' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.body.edge_group.assigned_locations.count).to eq 2
      check_locations = []
      @ega.conn.page.body.edge_group.assigned_locations.each {|x| check_locations << x.location.id}
      expect(check_locations).to include @locations[1]
      expect(check_locations).to include @locations[2]
    end

    it 'should be deleted' do
      edge_group.remove_edge_group
      expect(@ega.conn.page.code).to eq '204'
    end

    it 'should make sure CDN Edge Group is deleted' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.code).to eq '404'
    end
  end

  context 'Search' do
    before(:all) do
      @ega_1 = EdgeGroupActions.new.precondition
      @ega_2 = EdgeGroupActions.new.precondition
    end

    let (:edge_group_1) { @ega_1.edge_group }
    let (:edge_group_2) { @ega_2.edge_group }

    it 'should be created EG_1' do
      expect(edge_group_1.id).not_to be nil
    end

    it 'should be created EG_2' do
      expect(edge_group_2.id).not_to be nil
    end

    it 'should be edited EG_1' do
      edge_group_1.edit({edge_group: { label: ConstantsCdn::EG_LABEL_EDITED }})
      expect(@ega_1.conn.page.code).to eq '204'
    end

    it 'make sure Edge Group is edited' do
      @ega_1.get(edge_group_1.route_edge_group)
      expect(@ega_1.conn.page.body.edge_group.label).to eq ConstantsCdn::EG_LABEL_EDITED
      expect(@ega_1.conn.page.body.edge_group.assigned_locations.count).to eq 0
    end

    it 'should SEARCH (find EG_1 only)' do
      @ega_1.get(edge_group_1.route_edge_groups, { q: ConstantsCdn::EG_LABEL_EDITED })
      expect(@ega_1.conn.page.body.count).to eq 1
    end

    it 'should be deleted EG_1' do
      edge_group_1.remove_edge_group
      expect(@ega_1.conn.page.code).to eq '204'
    end

    it 'should make sure CDN EG_1 is deleted' do
      @ega_1.get(edge_group_1.route_edge_group)
      expect(@ega_1.conn.page.code).to eq '404'
    end

    it 'should be deleted EG_2' do
      edge_group_2.remove_edge_group
      expect(@ega_2.conn.page.code).to eq '204'
    end

    it 'should make sure CDN EG_2 is deleted' do
      @ega_2.get(edge_group_2.route_edge_group)
      expect(@ega_2.conn.page.code).to eq '404'
    end
  end

  context 'Complex tests'do
    before(:all) do
      @ega = EdgeGroupActions.new.precondition
      @ega.get(@ega.edge_group.route_edge_group, {available_locations: 'true'})
      @locations = []
      @ega.conn.page.body.edge_group.available_locations.each {|x| @locations << x.location.id}
    end

    let (:edge_group) { @ega.edge_group }
    it 'should be created' do
      expect(edge_group.id).not_to be nil
    end

    it 'should Get List of CDN Edge Groups' do
      @ega.get(edge_group.route_edge_groups)
      expect(@ega.conn.page.code).to eq '200'
    end

    it 'should Get List of Available CDN Edge Groups' do
      @ega.get(edge_group.route_available_eg)
      expect(@ega.conn.page.code).to eq '200'
    end

    it 'should Get CDN Edge Group Details' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.code).to eq '200'
      expect(@ega.conn.page.body.edge_group.assigned_locations.count).to eq 0
    end

    it 'should GET available locations' do
      @ega.get(edge_group.route_edge_group, {available_locations: 'true'})
      expect(@ega.conn.page.body.edge_group.available_locations.count).to be > 3
    end

    it 'should be editable Edge Group' do
      edge_group.edit({edge_group: { label: ConstantsCdn::EG_LABEL_EDITED }})
      expect(@ega.conn.page.code).to eq '204'
    end

    it 'make sure Edge Group is edited' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.body.edge_group.label).to eq ConstantsCdn::EG_LABEL_EDITED
      expect(@ega.conn.page.body.edge_group.assigned_locations.count).to eq 0
    end

    it 'should modify Edge Group' do
      edge_group.manipulation_with_locations(edge_group.route_manipulation('modify'), { locations: [@locations[1],\
                                                                                                    @locations[2]] })
      expect(@ega.conn.page.body.message).to eq "Edge Group was successfully modified."
      expect(@ega.conn.page.body.ids).to eq [@locations[1],@locations[2]]
    end

    it 'should make sure locations are modified' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.body.edge_group.label).to eq ConstantsCdn::EG_LABEL_EDITED
      expect(@ega.conn.page.body.edge_group.assigned_locations.count).to eq 2
      check_locations = []
      @ega.conn.page.body.edge_group.assigned_locations.each {|x| check_locations << x.location.id}
      expect(check_locations).to include @locations[1]
      expect(check_locations).to include @locations[2]
    end

    it 'should assign location' do
      edge_group.manipulation_with_locations(edge_group.route_manipulation('assign'), { location: @locations[0] })
      expect(@ega.conn.page.body.message).to eq 'Location was successfully assigned'
    end

    it 'should make sure locations are assigned' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.body.edge_group.label).to eq ConstantsCdn::EG_LABEL_EDITED
      expect(@ega.conn.page.body.edge_group.assigned_locations.count).to eq 3
      check_locations = []
      @ega.conn.page.body.edge_group.assigned_locations.each {|x| check_locations << x.location.id}
      expect(check_locations).to include @locations[0]
      expect(check_locations).to include @locations[1]
      expect(check_locations).to include @locations[2]
    end

    it 'should unassign location' do
      edge_group.manipulation_with_locations(edge_group.route_manipulation('unassign'),{ location: @locations[0] })
      @ega.edge_group.manipulation_with_locations(edge_group.route_manipulation('unassign'),{ location: @locations[1] })
      expect(@ega.conn.page.body.message).to eq 'Location was successfully unassigned'
    end

    it 'should make sure location is unassigned' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.body.edge_group.label).to eq ConstantsCdn::EG_LABEL_EDITED
      expect(@ega.conn.page.body.edge_group.assigned_locations.count).to eq 1
      check_locations = []
      @ega.conn.page.body.edge_group.assigned_locations.each {|x| check_locations << x.location.id}
      expect(check_locations).to include @locations[2]
    end

    it 'should not be unassigned the last location' do
      skip("https://onappdev.atlassian.net/browse/CORE-8582")
      edge_group.manipulation_with_locations(edge_group.route_manipulation('unassign'), { location: @locations[2] })
      expect(@ega.conn.page.body.message).to eq 'Location was successfully unassigned'
    end

    it 'should make sure the last location is not unassigned' do
      skip("https://onappdev.atlassian.net/browse/CORE-8582")
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.body.edge_group.label).to eq ConstantsCdn::EG_LABEL_EDITED
      expect(@ega.conn.page.body.edge_group.assigned_locations.count).to eq 1
      check_locations = []
      @ega.conn.page.body.edge_group.assigned_locations.each {|x| check_locations << x.location.id}
      expect(check_locations).to include @locations[2]
    end

    it 'should be deleted' do
      edge_group.remove_edge_group
      expect(@ega.conn.page.code).to eq '204'
    end

    it 'should make sure CDN Edge Group is deleted' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.code).to eq '404'
    end
  end

  context 'negative tests' do
    before(:all) do
      @ega = EdgeGroupActions.new.precondition
      @ega.get(@ega.edge_group.route_edge_group, {available_locations: 'true'})
      @locations = []
      @ega.conn.page.body.edge_group.available_locations.each {|x| @locations << x.location.id}
    end

    let (:edge_group) { @ega.edge_group }

    it 'should not be created with empty name' do
      edge_group.create_edge_group({ label: ""})
      expect(@ega.conn.page.code).to eq '422'
      expect(@ega.conn.page.body.errors.label[0]).to eq 'can\'t be blank'
      expect(@ega.conn.page.body.errors.label[1]).to eq 'is invalid'
    end

    it 'should not be created with name more than 255 characters' do
      edge_group.create_edge_group({ label: ConstantsCdn::EG_LABEL_255 })
      expect(@ega.conn.page.code).to eq '422'
      expect(@ega.conn.page.body.errors.label.first).to eq 'is too long (maximum is 255 characters)'
    end

    it 'should not be created with spec symbols' do
      edge_group.create_edge_group({ label: ConstantsCdn::EG_SPEC_NAME })
      expect(@ega.conn.page.code).to eq '422'
      expect(@ega.conn.page.body.errors.label.first).to eq 'is invalid'
    end

    it 'should not add not existed location by assign' do
      edge_group.manipulation_with_locations(edge_group.route_manipulation('modify'), { locations: [ConstantsCdn::EG_FAKE_LOCATION] })
      expect(@ega.conn.page.body.message).to eq 'Edge Group was modified with some errors.'
      expect(@ega.conn.page.body.error).to eq "Locations with IDs [#{ConstantsCdn::EG_FAKE_LOCATION}] are unavailable"
    end

    it 'should not add not existed location by modify' do
      edge_group.manipulation_with_locations(edge_group.route_manipulation('modify'), { locations: ConstantsCdn::EG_FAKE_LOCATION })
      expect(@ega.conn.page.body.message).to eq 'Edge Group was modified with some errors.'
      expect(@ega.conn.page.body.error).to eq "Locations with IDs [#{ConstantsCdn::EG_FAKE_LOCATION}] are unavailable"
    end

    it 'should not unassign not existed location by unassign' do
      edge_group.manipulation_with_locations(edge_group.route_manipulation('unassign'),{ location: ConstantsCdn::EG_FAKE_LOCATION })
      expect(@ega.conn.page.body.error).to eq 'Given location is not assigned so it can not be unassigned.'
    end

    it 'should assign already existed location' do
      edge_group.manipulation_with_locations(edge_group.route_manipulation('assign'), { location: @locations[1] })
      edge_group.manipulation_with_locations(edge_group.route_manipulation('assign'), { location: @locations[1] })
      expect(@ega.conn.page.body.error).to eq 'Location is already assigned.'
    end

    it 'should be deleted' do
      edge_group.remove_edge_group
      expect(@ega.conn.page.code).to eq '204'
    end

    it 'should make sure CDN Edge Group is deleted' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.code).to eq '404'
    end

    context 'two EG with the same name' do
      before(:all) do
        @ega_1 = EdgeGroupActions.new.precondition
      end

      let (:edge_group_1) { @ega_1.edge_group }

      it 'should be deleted two EGs(before all)' do
        edge_group_1.remove_edge_group
        expect(@ega_1.conn.page.code).to eq '204'
      end

      it 'should create EG_1' do
        edge_group_1.create_edge_group({ label: ConstantsCdn::EG_SAME_NAME})
        expect(@ega_1.conn.page.code).to eq '201'
      end

      it 'make sure EG_1 is created' do
        @ega_1.get(edge_group_1.route_edge_group)
        expect(@ega_1.conn.page.code).to eq '200'
      end

      it 'should not be create EG_2 with the same name' do
        edge_group_1.create_edge_group({ label: ConstantsCdn::EG_SAME_NAME})
        expect(@ega_1.conn.page.code).to eq '422'
        expect(@ega_1.conn.page.body.errors.label.first).to eq 'has already been taken'
      end

      it 'should be deleted EG_1' do
        edge_group_1.remove_edge_group
        expect(@ega_1.conn.page.code).to eq '204'
      end

      it 'should make sure EG_1 is deleted' do
        @ega_1.get(edge_group_1.route_edge_group)
        expect(@ega_1.conn.page.code).to eq '404'
      end
    end
  end

  context 'billing plan' do
    before(:all) do
      @ega = EdgeGroupActions.new.precondition
      @bpa = BillingPlanActions.new.precondition
      @bpa.billing_plan.create_billing_plan
      @eg_limit = @bpa.billing_plan.create_limit_eg(@ega.edge_group.id)
    end

    let (:edge_group) { @ega.edge_group }
    let (:billing_plan) { @bpa.billing_plan }

    it 'should be copied(billing plan)' do
      expect(billing_plan.id).not_to be nil
    end

    it 'should be created(edge_group)' do
      expect(edge_group.id).not_to be nil
    end

    it 'should be created(limit_eg)' do
      expect(@eg_limit.id).not_to be nil
    end

    it 'make sure billing plan has been created' do
      @bpa.get(billing_plan.route_billing_plan)
      expect(@bpa.conn.page.code).to eq '200'
    end

    it 'make sure EdgeGroup has been created' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.code).to eq '200'
    end

    it 'make sure Limit_eg has been added' do
      @eg_limit.get
      expect(@ega.conn.page.code).to eq '200'
    end

    it 'make sure CDN Edge Group associated with billing plan cannot be deleted' do
      edge_group.remove_edge_group
      expect(@ega.conn.page.code).to eq '422'
      expect(@ega.conn.page.body).to eq "{\"error\":\"edge groups associated with billing plans cannot be deleted\"}"
    end

    it 'make sure CDN EdgeGroup is not deleted' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.code).to eq '200'
    end

    it 'should be deleted eg_limit' do
      @eg_limit.delete
      expect(@eg_limit.interface.conn.page.code).to eq '204'
    end

    it 'should be removed(billing_plan)' do
      billing_plan.remove_billing_plan
      expect(@bpa.conn.page.code).to eq '204'
    end

    it 'make sure the billing plan is removed' do
      @bpa.get(billing_plan.route_billing_plan)
      expect(@bpa.conn.page.code).to eq '404'
    end

    it 'should be deleted(EdgeGroup)' do
      edge_group.remove_edge_group
      expect(@ega.conn.page.code).to eq '204'
    end

    it 'make sure CDN Edge Group is deleted' do
      @ega.get(edge_group.route_edge_group)
      expect(@ega.conn.page.code).to eq '404'
    end
  end
end
