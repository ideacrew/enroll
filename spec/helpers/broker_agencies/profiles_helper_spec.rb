require 'rails_helper'

RSpec.describe BrokerAgencies::ProfilesHelper, dbclean: :after_each, :type => :helper do

  let(:user) { FactoryGirl.create(:user) }
  let(:person) { FactoryGirl.create(:person, user: user) }

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

  describe 'show_destroy_for_staff?' do

    it 'should return false if current user has broker role' do
      allow(person).to receive(:broker_role).and_return true
      expect(helper.show_destroy_for_staff?(user)). to eq false
    end

    it 'should return true if current user does not have broker role' do
      allow(person).to receive(:broker_role).and_return false
      expect(helper.show_destroy_for_staff?(user)). to eq true
    end

  end

  describe 'is_primary_broker?' do

    it 'should return false if current user has broker role' do
      allow(person).to receive(:broker_role).and_return true
      expect(helper.is_primary_broker?(person)). to eq true
    end

    it 'should return true if current user does not have broker role' do
      allow(person).to receive(:broker_role).and_return false
      expect(helper.is_primary_broker?(person)). to eq false
    end

  end

end