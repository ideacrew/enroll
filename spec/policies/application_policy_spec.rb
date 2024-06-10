# frozen_string_literal: true

require 'rails_helper'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe ApplicationPolicy, type: :model do
    subject { described_class }

    permissions :active_associated_individual_market_family_broker_staff? do
      context 'for case where the logged in user does not have a family' do
        let(:market_kind) { :both }
        let(:broker_person) { FactoryBot.create(:person) }
        let(:broker_role) { FactoryBot.create(:broker_role, person: broker_person) }
        let(:broker_staff_person) { FactoryBot.create(:person) }

        let(:broker_staff_state) { 'active' }

        let(:broker_staff) do
          FactoryBot.create(
            :broker_agency_staff_role,
            person: broker_staff_person,
            aasm_state: broker_staff_state,
            benefit_sponsors_broker_agency_profile_id: broker_agency_id
          )
        end
        let(:broker_staff_user) { FactoryBot.create(:user, person: broker_staff_person) }

        let(:site) do
          FactoryBot.create(
            :benefit_sponsors_site,
            :with_benefit_market,
            :as_hbx_profile,
            site_key: ::EnrollRegistry[:enroll_app].settings(:site_key).item
          )
        end

        let(:broker_agency_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
        let(:broker_agency_profile) { broker_agency_organization.broker_agency_profile }
        let(:broker_agency_id) { broker_agency_profile.id }

        before do
          broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
          broker_person.create_broker_agency_staff_role(
            benefit_sponsors_broker_agency_profile_id: broker_role.benefit_sponsors_broker_agency_profile_id
          )
          broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id, market_kind: market_kind)
          broker_role.approve!
          broker_staff
        end

        context 'when the broker agency staff does not belong to any family' do
          it 'denies access' do
            expect(subject).not_to permit(broker_staff_user, broker_person)
          end
        end
      end
    end
  end
end
