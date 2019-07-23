require 'rails_helper'

RSpec.describe BrokerAgencies::ProfilesHelper, dbclean: :after_each, :type => :helper do

  let(:user) { FactoryGirl.create(:user) }
  let(:person) { FactoryGirl.create(:person, user: user) }
  let(:broker_agency_profile) {FactoryGirl.create(:broker_agency_profile)}
  let(:person2) { broker_agency_profile.primary_broker_role.person }

  describe 'disable_edit_broker_agency?' do

    it 'should return false if current user has broker role' do
      allow(person).to receive(:broker_role).and_return true
      expect(helper.disable_edit_broker_agency?(user)). to eq false
    end

    it 'should return true if current user does not have broker role' do
      allow(person).to receive(:broker_role).and_return false
      expect(helper.disable_edit_broker_agency?(user)). to eq true
    end

    it 'should return true if current user has staff role' do
      allow(user).to receive(:has_hbx_staff_role?).and_return true
      expect(helper.disable_edit_broker_agency?(user)). to eq false
    end

  end

  describe 'can_show_destroy?' do

    it 'should return true if person is the primary broker' do
      expect(helper.can_show_destroy?(person2, broker_agency_profile)). to eq true
    end

    it 'should return false if the person is not the primary broker' do
      expect(helper.can_show_destroy?(person, broker_agency_profile)). to eq false
    end

  end

end