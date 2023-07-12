require 'rails_helper'

require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"
module SponsoredBenefits
  RSpec.describe Effective::Datatables::BrokerAgencyPlanDesignOrganizationDatatable, dbclean: :after_each do
    include_context "set up broker agency profile for BQT, by using configuration settings"

    describe '#authorized?' do

      context 'when current user does not exist' do
        let(:user) { nil }

        it 'should not authorize access' do
          expect(subject.authorized?(user, nil, nil, nil)).to eq(false)
        end
      end

      context 'hbx staff role' do
        context 'when current user exists without staff role' do
          let(:user) { FactoryBot.create(:user) }

          it 'should not authorize access' do
            expect(subject.authorized?(user, nil, nil, nil)).to eq(false)
          end
        end

        context 'when current user exists with staff role' do
          let!(:user_with_hbx_staff_role) { FactoryBot.create(:user, :with_hbx_staff_role) }
          let!(:person) { FactoryBot.create(:person, user: user_with_hbx_staff_role)}

          it 'should authorize access' do
            expect(subject.authorized?(user_with_hbx_staff_role, nil, nil, nil)).to eq(true)
          end
        end
      end

      context 'when current user exists with broker agency staff role' do
        let!(:ba_profile_id) {broker_agency_profile.id}
        let!(:broker_agency_staff_role) do
          person.broker_agency_staff_roles << BrokerAgencyStaffRole.new(benefit_sponsors_broker_agency_profile_id: ba_profile_id, aasm_state: 'active')
          person.save!
          person.broker_agency_staff_roles.first
        end
        let!(:person) {  FactoryBot.create(:person)}
        let!(:user_with_ba_staff_role) { FactoryBot.create(:user, person: person, roles: ["broker_agency_staff"])}

        context 'and belongs to profile' do
          let!(:subject) { described_class.new(profile_id: ba_profile_id) }

          it 'should authorize access' do
            expect(subject.authorized?(user_with_ba_staff_role, nil, nil, nil)).to eq(true)
          end
        end

        context 'and does not belongs to profile' do
          let!(:subject) { described_class.new(profile_id: "test") }

          it 'should not authorize access' do
            expect(subject.authorized?(user_with_ba_staff_role, nil, nil, nil)).to eq(false)
          end
        end
      end
    end
  end
end