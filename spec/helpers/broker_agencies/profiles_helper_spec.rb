require 'rails_helper'

RSpec.describe BrokerAgencies::ProfilesHelper, dbclean: :after_each, :type => :helper do

  let!(:site)                          { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let(:organization_with_hbx_profile)  { site.owner_organization }
  let!(:organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
  let!(:broker_agency_profile1) { organization.broker_agency_profile }
  let(:user) { FactoryBot.create(:user) }
  let(:person) { FactoryBot.create(:person, user: user) }
  let(:person2) { FactoryBot.create(:person) }
  let(:person3) { FactoryBot.create(:person) }
  let!(:broker_role) { FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile1.id, person: person) }
  let!(:broker_role1) { FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: '123', person: person3) }
  
  describe 'disable_edit_broker_agency?' do
    it 'should return false if current user has broker role' do
      allow(person).to receive(:broker_role).and_return true
      expect(helper.disable_edit_broker_agency?(user)).to be_falsey
    end

    it 'should return true if current user does not have broker role' do
      allow(person).to receive(:broker_role).and_return false
      expect(helper.disable_edit_broker_agency?(user)). to eq true
    end

    it 'should return true if current user has staff role' do
      allow(user).to receive(:has_hbx_staff_role?).and_return true
      expect(helper.disable_edit_broker_agency?(user)).to be_falsey
    end
  end

  describe 'can_show_destroy_for_brokers?' do
    context "total broker staff count" do
      it "should return false if single staff member remains" do
        expect(helper.can_show_destroy_for_brokers?(person, 1, broker_agency_profile1)).to be_falsey
      end
    end

    context "with broker role" do
      before do
        broker_agency_profile1.update_attributes!(primary_broker_role: broker_role)
      end

      it 'should return false if staff has primary broker role' do
        expect(helper.can_show_destroy_for_brokers?(person, 2, broker_agency_profile1)). to be_falsey
      end

      it 'should return true if staff DOES NOT HAVE broker role' do
        expect(helper.can_show_destroy_for_brokers?(person2, 2, broker_agency_profile1)).to be_truthy
      end

      it 'should return true if staff has broker role, but it is not primary' do
        expect(helper.can_show_destroy_for_brokers?(person3, 2, broker_agency_profile1)).to be_truthy
      end
    end
  end

  describe 'can_show_destroy_for_ga?' do
    context "total general agency staff count" do
      it "should return false if single staff member remains" do
        expect(helper.can_show_destroy_for_ga?(person, 1)).to be_falsey
      end
    end

    context "with general agency staff" do
      it 'should return false if staff has primary ga staff role' do
        allow(person).to receive(:general_agency_primary_staff).and_return true
        expect(helper.can_show_destroy_for_ga?(person, 2)).to be_falsey
      end

      it 'should return true if staff DOES NOT HAVE has primary ga staff role' do
        allow(person).to receive(:general_agency_primary_staff).and_return false
        expect(helper.can_show_destroy_for_ga?(person2, 2)).to be_truthy
      end
    end
  end
end
