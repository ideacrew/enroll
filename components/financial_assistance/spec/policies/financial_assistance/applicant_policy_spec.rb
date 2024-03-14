# frozen_string_literal: true

require 'rails_helper'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe FinancialAssistance::ApplicantPolicy, dbclean: :after_each, type: :model do
    subject { described_class }

    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:consumer_role) { person.consumer_role }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:primary_family_member) { family.primary_applicant }
    let(:dependent_person) do
      pr = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)
      person.ensure_relationship_with(pr, 'spouse')
      pr
    end
    let(:dependent_member) { FactoryBot.create(:family_member, family: family, person: dependent_person) }
    let(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id) }
    let(:primary_applicant) do
      FactoryBot.create(
        :financial_assistance_applicant,
        application: application,
        family_member_id: primary_family_member.id,
        person_hbx_id: person.hbx_id
      )
    end
    let(:dependent_applicant) do
      FactoryBot.create(
        :financial_assistance_applicant,
        application: application,
        family_member_id: dependent_member.id,
        person_hbx_id: dependent_person.hbx_id
      )
    end

    permissions :edit? do
      before do
        primary_applicant
        consumer_role.move_identity_documents_to_verified
      end

      context 'when a valid user is logged in' do
        context 'when the user is a consumer' do
          let(:user_of_family) { FactoryBot.create(:user, person: person) }
          let(:logged_in_user) { user_of_family }

          context 'with ridp verified' do
            it 'grants access' do
              expect(subject).to permit(logged_in_user, dependent_applicant)
            end
          end

          context 'without ridp verified' do
            it 'denies access' do
              consumer_role.update_attributes(identity_validation: 'rejected')
              expect(subject).not_to permit(logged_in_user, dependent_applicant)
            end
          end
        end

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

          let(:logged_in_user) { hbx_admin_user }

          context 'when the hbx staff has the correct permission' do
            let(:permission) { FactoryBot.create(:permission, :super_admin) }

            it 'grants access' do
              expect(subject).to permit(logged_in_user, dependent_applicant)
            end
          end

          context 'when the hbx staff does not have the correct permission' do
            let(:permission) { FactoryBot.create(:permission, :developer) }

            it 'denies access' do
              expect(subject).not_to permit(logged_in_user, dependent_applicant)
            end
          end
        end

        context 'when the user is an assigned broker' do
          let(:market_kind) { :both }
          let(:broker_person) { FactoryBot.create(:person) }
          let(:broker_role) { FactoryBot.create(:broker_role, person: broker_person) }
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

          let(:logged_in_user) { broker_user }

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
            broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id, market_kind: market_kind)
            broker_role.approve!
            broker_agency_account
          end

          context 'with active associated individual market certified broker' do
            context 'consumer RIDP is verified' do
              let(:baa_active) { true }

              it 'grants access' do
                expect(subject).to permit(logged_in_user, dependent_applicant)
              end
            end

            context 'consumer RIDP is unverified' do
              let(:baa_active) { true }

              it 'denies access' do
                consumer_role.update_attributes(identity_validation: 'na', application_validation: 'na')
                expect(subject).not_to permit(logged_in_user, dependent_applicant)
              end
            end
          end

          context 'with active associated shop market certified broker' do
            let(:baa_active) { false }
            let(:market_kind) { :shop }

            it 'denies access' do
              expect(subject).not_to permit(logged_in_user, dependent_applicant)
            end
          end

          context 'with unassociated broker' do
            let(:baa_active) { false }

            it 'denies access' do
              expect(subject).not_to permit(logged_in_user, dependent_applicant)
            end
          end
        end

        context 'when the user is a broker staff' do
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

          let(:logged_in_user) { broker_staff_user }

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
            broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id, market_kind: market_kind)
            broker_role.approve!
            broker_agency_account
            broker_staff
          end

          context 'with active associated individual market broker staff' do
            context 'consumer RIDP is verified' do
              let(:baa_active) { true }

              it 'grants access' do
                expect(subject).to permit(logged_in_user, dependent_applicant)
              end
            end

            context 'consumer RIDP is unverified' do
              let(:baa_active) { true }

              it 'denies access' do
                consumer_role.update_attributes(identity_validation: 'na', application_validation: 'na')
                expect(subject).not_to permit(logged_in_user, dependent_applicant)
              end
            end
          end

          context 'with active associated shop market broker staff' do
            let(:baa_active) { false }
            let(:market_kind) { :shop }

            it 'denies access' do
              expect(subject).not_to permit(logged_in_user, dependent_applicant)
            end
          end

          context 'with unassociated broker staff' do
            let(:baa_active) { false }

            it 'denies access' do
              expect(subject).not_to permit(logged_in_user, dependent_applicant)
            end
          end

          context 'with unapproved broker staff' do
            let(:baa_active) { true }
            let(:broker_staff_state) { 'broker_agency_pending' }

            it 'denies access' do
              expect(subject).not_to permit(logged_in_user, dependent_applicant)
            end
          end

          context 'with broker_agency_declined broker staff' do
            let(:baa_active) { true }
            let(:broker_staff_state) { 'broker_agency_declined' }

            it 'denies access' do
              expect(subject).not_to permit(logged_in_user, dependent_applicant)
            end
          end

          context 'with broker_agency_terminated broker staff' do
            let(:baa_active) { true }
            let(:broker_staff_state) { 'broker_agency_terminated' }

            it 'denies access' do
              expect(subject).not_to permit(logged_in_user, dependent_applicant)
            end
          end
        end
      end

      context 'when a valid user is not logged in' do
        let(:no_role_person) { FactoryBot.create(:person) }
        let(:no_role_user) { FactoryBot.create(:user, person: no_role_person) }
        let(:logged_in_user) { no_role_user }

        it 'denies access' do
          expect(subject).not_to permit(logged_in_user, dependent_applicant)
        end
      end
    end
  end
end
