# frozen_string_literal: true

require 'rails_helper'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe ConsumerRolePolicy, dbclean: :after_each, type: :model do
    subject { described_class }

    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:consumer_role) { person.consumer_role }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

    permissions :modify_and_view_as_self_or_broker? do
      context 'when a valid user is logged in' do
        context 'when the user is a consumer' do
          let(:user_of_family) { FactoryBot.create(:user, person: person) }
          let(:logged_in_user) { user_of_family }

          it 'grants access' do
            expect(subject).to permit(logged_in_user, consumer_role)
          end
        end

        context 'when the user is an assigned broker' do
          let(:broker_person) { FactoryBot.create(:person, :with_broker_role) }
          let(:broker_role) { broker_person.broker_role }
          let(:broker_user) { FactoryBot.create(:user, person: broker_person) }

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

          let(:broker_agency_account) do
            family.broker_agency_accounts.create!(
              benefit_sponsors_broker_agency_profile_id: broker_agency_id,
              writing_agent_id: broker_role.id,
              is_active: baa_active,
              start_on: TimeKeeper.date_of_record
            )
          end

          before do
            broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
            broker_person.create_broker_agency_staff_role(
              benefit_sponsors_broker_agency_profile_id: broker_role.benefit_sponsors_broker_agency_profile_id
            )
            broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id)
            broker_role.approve!
            broker_agency_account
          end

          context 'with associated broker' do
            let(:baa_active) { true }

            it 'grants access' do
              expect(subject).to permit(broker_user, consumer_role)
            end
          end

          context 'with unassociated broker' do
            let(:baa_active) { false }

            it 'denies access' do
              expect(subject).not_to permit(broker_user, consumer_role)
            end
          end
        end
      end

      context 'when a valid user is not logged in' do
        let(:no_role_person) { FactoryBot.create(:person) }
        let(:no_role_user) { FactoryBot.create(:user, person: no_role_person) }

        it 'denies access' do
          expect(subject).not_to permit(no_role_user, consumer_role)
        end
      end
    end

    permissions :ridp_verified? do
      context 'when the user is a consumer' do
        let(:user_of_family) { FactoryBot.create(:user, person: person) }
        let(:logged_in_user) { user_of_family }

        context 'with ridp verified' do
          it 'grants access' do
            consumer_role.move_identity_documents_to_verified
            expect(subject).to permit(logged_in_user, consumer_role)
          end
        end

        context 'without ridp verified' do
          it 'denies access' do
            consumer_role.update_attributes(identity_validation: 'rejected')
            expect(subject).not_to permit(logged_in_user, consumer_role)
          end
        end
      end
    end

    permissions :hbx_staff_modify_family? do
      context 'when the user is a hbx staff' do
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

        context 'when the hbx staff has the correct permission' do
          let(:permission) { FactoryBot.create(:permission, :super_admin) }

          it 'grants access' do
            expect(subject).to permit(hbx_admin_user, consumer_role)
          end
        end

        context 'when the hbx staff does not have the correct permission' do
          let(:permission) { FactoryBot.create(:permission, :developer) }

          it 'denies access' do
            expect(subject).not_to permit(hbx_admin_user, consumer_role)
          end
        end
      end
    end
  end
end
