# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PersonPolicy, type: :policy do
  subject { described_class }

  permissions :can_download_document? do
    let(:hbx_profile) do
      FactoryBot.create(
        :hbx_profile,
        :normal_ivl_open_enrollment,
        us_state_abbreviation: EnrollRegistry[:enroll_app].setting(:state_abbreviation).item,
        cms_id: "#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.upcase}0"
      )
    end

    let(:hbx_staff_person) { FactoryBot.create(:person) }

    let(:hbx_staff_role) do
      hbx_staff_person.create_hbx_staff_role(
        permission_id: permission.id,
        subrole: permission.name,
        hbx_profile: hbx_profile
      )
    end

    let(:hbx_admin_user) do
      FactoryBot.create(:user, person: hbx_staff_person)
      hbx_staff_role.person.user
    end

    let(:permission) { FactoryBot.create(:permission, :super_admin) }

    context 'with broker and broker agency staff roles' do
      let(:broker_person) { FactoryBot.create(:person) }
      let(:broker_role) { FactoryBot.create(:broker_role, person: broker_person) }
      let(:broker_user) { FactoryBot.create(:user, person: broker_person) }

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
        broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id, market_kind: :both)
        broker_role.approve!
        broker_staff
      end

      # There are 2 people.
      # person A has active broker agency staff role
      # person B has active broker role
      # person A is trying to download/view a document of associated Broker Agency Profile.
      # Inbox Messages are attached to associated Broker Role of a Broker Agency Profile.
      # So, technically person A should be able to access person B messages if both are active and associated with same Broker Agency Profile.
      context 'active broker agency staff tries to access pdf of an inbox message of Broker Agency Profile' do
        it 'grants access' do
          expect(subject).to permit(broker_staff_user, broker_person)
        end
      end

      # There is 1 person.
      # person A has active broker role
      # person A is trying to download/view a document of associated Broker Agency Profile.
      # Inbox Messages are attached to associated Broker Role of a Broker Agency Profile.
      # So, person A should be able to access their own messages irrespective of if they are associated to a Broker Agency Profile.
      context 'active broker tries to access pdf of an inbox message of Broker Agency Profile' do
        it 'grants access' do
          expect(subject).to permit(broker_user, broker_person)
        end
      end

      # There are 2 people.
      # person A has inactive broker agency staff role
      # person B has active broker role
      # person A is trying to download/view a document of associated Broker Agency Profile.
      # Inbox Messages are attached to associated Broker Role of a Broker Agency Profile.
      # So, technically person A should NOT be able to access person B messages as person A is not active anymore.
      context 'inactive broker agency staff tries to access pdf of an inbox message of Broker Agency Profile' do
        let(:broker_staff_state) { 'broker_agency_terminated' }

        it 'denies access' do
          expect(subject).not_to permit(broker_staff_user, broker_person)
        end
      end
    end

    context 'with an admin and a consumer' do
      let(:consumer_person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
      let(:consumer_role) { consumer_person.consumer_role }
      let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: consumer_person) }

      before do
        consumer_role.move_identity_documents_to_verified
      end

      it 'grants access' do
        expect(subject).to permit(hbx_admin_user, consumer_person)
      end
    end
  end
end
