# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BrokerRole, type: :model, dbclean: :after_each do
  describe '#create_basr_for_person_with_consumer_role' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:broker_role) { FactoryBot.create(:broker_role, person: person) }
    let(:user) { FactoryBot.create(:user, person: person) }

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

    let(:broker_agency_organization2) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let(:broker_agency_profile2) { broker_agency_organization2.broker_agency_profile }

    before :each do
      allow(EnrollRegistry).to receive(:feature_enabled?).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:broker_role_consumer_enhancement).and_return(
        brce_feature_enabled
      )
    end

    context 'RR feature is turned OFF' do
      let(:brce_feature_enabled) { false }

      it 'returns nil without creating a new BrokerAgencyStaffRole' do
        expect(broker_role.create_basr_for_person_with_consumer_role).to be_nil
        expect(person.broker_agency_staff_roles.to_a).to be_empty
      end
    end

    context 'RR feature is turned ON' do
      let(:brce_feature_enabled) { true }

      context 'when:
        - person has no active consumer role
        - person has a broker role' do

        let(:person) { FactoryBot.create(:person) }

        it 'returns nil without creating a new BrokerAgencyStaffRole' do
          expect(broker_role.create_basr_for_person_with_consumer_role).to be_nil
          expect(person.broker_agency_staff_roles.to_a).to be_empty
        end
      end

      context 'when:
        - person has active consumer role
        - person has a broker role
        - person does not have a user role' do

        it 'returns nil without creating a new BrokerAgencyStaffRole' do
          expect(broker_role.create_basr_for_person_with_consumer_role).to be_nil
          expect(person.broker_agency_staff_roles.to_a).to be_empty
        end
      end

      context 'when:
        - person has active consumer role
        - person has a broker role
        - person has a user role
        - person has a broker agency staff role in broker_agency_pending state for the broker agency of the broker role' do

        let(:matching_basr) do
          person.create_broker_agency_staff_role(
            benefit_sponsors_broker_agency_profile_id: broker_role.benefit_sponsors_broker_agency_profile_id
          )
        end

        before do
          broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
          user
          matching_basr
        end

        it 'returns nil without creating a new BrokerAgencyStaffRole' do
          expect(broker_role.create_basr_for_person_with_consumer_role).to be_nil
          expect(person.broker_agency_staff_roles.to_a).to eq([matching_basr])
        end
      end

      context 'when:
        - person has active consumer role
        - person has a broker role
        - person has a user role
        - person has a broker agency staff role in non broker_agency_pending state for the broker agency of the broker role' do

        let(:matching_basr) do
          person.create_broker_agency_staff_role(
            benefit_sponsors_broker_agency_profile_id: broker_role.benefit_sponsors_broker_agency_profile_id
          )
        end

        before do
          broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
          user
          matching_basr.update_attributes!(aasm_state: 'active')
        end

        it 'returns newly created BrokerAgencyStaffRole' do
          result = broker_role.create_basr_for_person_with_consumer_role
          expect(result).to be_a(BrokerAgencyStaffRole)
          expect(result.broker_agency_pending?).to be_truthy
          expect(person.broker_agency_staff_roles.count).to eq(2)
        end
      end

      context 'when:
        - person has active consumer role
        - person has a broker role
        - person has a user role
        - person has a broker agency staff role for a broker agency which is not of the broker role' do

        let(:non_matching_basr) do
          person.create_broker_agency_staff_role(
            benefit_sponsors_broker_agency_profile_id: broker_agency_profile2.id
          )
        end

        before do
          broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
          user
          non_matching_basr
        end

        it 'returns newly created BrokerAgencyStaffRole' do
          result = broker_role.create_basr_for_person_with_consumer_role
          expect(result).to be_a(BrokerAgencyStaffRole)
          expect(result.broker_agency_pending?).to be_truthy
          expect(person.broker_agency_staff_roles.count).to eq(2)
        end
      end

      context 'when:
        - person has active consumer role
        - person has a broker role
        - person has a user role
        - person does not have a broker agency staff role' do

        before do
          broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
          user
        end

        it 'returns newly created BrokerAgencyStaffRole' do
          result = broker_role.create_basr_for_person_with_consumer_role
          expect(result).to be_a(BrokerAgencyStaffRole)
          expect(result.broker_agency_pending?).to be_truthy
          expect(person.broker_agency_staff_roles.count).to eq(1)
        end
      end
    end
  end
end
