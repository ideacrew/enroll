# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Effective::Datatables::PlanDesignEmployeeDatatable, dbclean: :after_each do
  let(:profile_id) { BSON::ObjectId.new.to_s }
  subject { described_class.new({ id: 'sponsorship_id', profile_id: profile_id }) }

  describe '#authorized?' do
    context 'when current user does not exist' do
      let(:user) { nil }

      it 'should not authorize access' do
        expect(subject.authorized?(user, nil, nil, nil)).to be_falsey
      end
    end

    context 'when current user exists without hbx staff role' do
      let(:user) { double('User', has_hbx_staff_role?: nil) }

      it 'should not authorize access' do
        expect(subject.authorized?(user, nil, nil, nil)).to be_falsey
      end
    end

    context 'when current user exists with hbx staff role' do
      let(:user) { double('User', has_hbx_staff_role?: true) }

      it 'should authorize access' do
        expect(subject.authorized?(user, nil, nil, nil)).to be_truthy
      end
    end

    context 'when current user exists with broker role' do
      let(:broker_role) { double('BrokerRole', benefit_sponsors_broker_agency_profile_id: profile_id) }
      let(:person) { double('Person', broker_role: broker_role) }
      let(:user) { double('User', has_hbx_staff_role?: nil, person: person) }
      let(:ba_profile) { instance_double(BenefitSponsors::Organizations::BrokerAgencyProfile, id: profile_id) }

      before do
        allow(::BenefitSponsors::Organizations::Profile).to receive(:find).with(profile_id).and_return(ba_profile)
      end

      it 'should authorize access' do
        expect(subject.authorized?(user, nil, nil, nil)).to be_truthy
      end
    end

    context 'when current user exists with general agency staff role' do
      let(:ga_staff_role) { double('GeneralAgencyStaffRole', benefit_sponsors_general_agency_profile_id: profile_id) }
      let(:person) { double('Person', active_general_agency_staff_roles: [ga_staff_role], broker_role: nil) }
      let(:user) { double('User', has_hbx_staff_role?: nil, person: person) }
      let(:ga_account) { double('GeneralAgencyAccount', benefit_sponsrship_general_agency_profile_id: profile_id) }
      let(:ga_profile) { double(BenefitSponsors::Organizations::GeneralAgencyProfile, id: profile_id, general_agency_accounts: [ga_account]) }

      before do
        allow(::BenefitSponsors::Organizations::Profile).to receive(:find).with(profile_id).and_return(ga_profile)
      end

      it 'should authorize access' do
        expect(subject.authorized?(user, nil, nil, nil)).to be_truthy
      end
    end
  end
end
