# frozen_string_literal: true

RSpec.describe Insured::GroupSelectionController, type: :controller do
  before :all do
    DatabaseCleaner.clean
  end

  after :all do
    DatabaseCleaner.clean
  end

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:consumer_role) { person.consumer_role }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:primary_family_member) { family.primary_applicant }

  let(:rating_area) { FactoryBot.create_default(:benefit_markets_locations_rating_area) }

  let(:product) do
    FactoryBot.create(
      :benefit_markets_products_health_products_health_product,
      hios_id: '11111111122301-01',
      csr_variant_id: '01',
      metal_level_kind: :silver,
      application_period: TimeKeeper.date_of_record.beginning_of_year..TimeKeeper.date_of_record.end_of_year,
      benefit_market_kind: :aca_individual
    )
  end

  let(:enrollment_effective_date) { TimeKeeper.date_of_record + 1.month }

  let(:ivl_enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      family: family,
      household: family.active_household,
      coverage_kind: 'health',
      effective_on: enrollment_effective_date,
      enrollment_kind: 'special_enrollment',
      kind: 'individual',
      consumer_role_id: consumer_role.id,
      rating_area_id: rating_area.id,
      product: product
    )
  end

  let(:params) { { hbx_enrollment_id: ivl_enrollment.id, term_date: nil, term_or_cancel: 'cancel' } }
  let(:session_params) { { person_id: ivl_enrollment.family.primary_person.id } }

  before do
    consumer_role.move_identity_documents_to_verified
    sign_in(logged_in_user)
  end

  describe 'POST #term_or_cancel' do
    context 'when a valid user is logged in' do
      context 'when the user is a consumer' do
        let(:user_of_family) { FactoryBot.create(:user, person: person) }
        let(:logged_in_user) { user_of_family }

        context 'with ridp verified' do
          it 'cancels enrollment' do
            post :term_or_cancel, params: params, session: session_params
            expect(ivl_enrollment.reload.coverage_canceled?).to be_truthy
            expect(response).to redirect_to(family_account_path)
          end
        end

        context 'without ridp verified' do
          it 'denies access' do
            consumer_role.update_attributes(identity_validation: 'na', application_validation: 'na')
            post :term_or_cancel, params: params, session: session_params
            expect(flash[:error]).to eq('Access not allowed for family_policy.create?, (Pundit policy)')
            expect(response.status).to eq(302)
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

          it 'cancels enrollment' do
            post :term_or_cancel, params: params, session: session_params
            expect(ivl_enrollment.reload.coverage_canceled?).to be_truthy
            expect(response).to redirect_to(family_account_path)
          end
        end

        context 'when the hbx staff does not have the correct permission' do
          let(:permission) { FactoryBot.create(:permission, :developer) }

          it 'denies access' do
            consumer_role.update_attributes(identity_validation: 'na', application_validation: 'na')
            post :term_or_cancel, params: params, session: session_params
            expect(flash[:error]).to eq('Access not allowed for family_policy.create?, (Pundit policy)')
            expect(response.status).to eq(302)
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

            it 'cancels enrollment' do
              post :term_or_cancel, params: params, session: session_params
              expect(ivl_enrollment.reload.coverage_canceled?).to be_truthy
              expect(response).to redirect_to(family_account_path)
            end
          end
        end

        context 'with active associated shop market certified broker' do
          let(:baa_active) { false }
          let(:market_kind) { :shop }

          it 'denies access' do
            consumer_role.update_attributes(identity_validation: 'na', application_validation: 'na')
            post :term_or_cancel, params: params, session: session_params
            expect(flash[:error]).to eq('Access not allowed for family_policy.create?, (Pundit policy)')
            expect(response.status).to eq(302)
          end
        end

        context 'with unassociated broker' do
          let(:baa_active) { false }

          it 'denies access' do
            consumer_role.update_attributes(identity_validation: 'na', application_validation: 'na')
            post :term_or_cancel, params: params, session: session_params
            expect(flash[:error]).to eq('Access not allowed for family_policy.create?, (Pundit policy)')
            expect(response.status).to eq(302)
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

            it 'cancels enrollment' do
              post :term_or_cancel, params: params, session: session_params
              expect(ivl_enrollment.reload.coverage_canceled?).to be_truthy
              expect(response).to redirect_to(family_account_path)
            end
          end
        end

        context 'with unapproved broker staff' do
          let(:baa_active) { true }
          let(:broker_staff_state) { 'broker_agency_pending' }

          it 'denies access' do
            consumer_role.update_attributes(identity_validation: 'na', application_validation: 'na')
            post :term_or_cancel, params: params, session: session_params
            expect(flash[:error]).to eq('Access not allowed for family_policy.create?, (Pundit policy)')
            expect(response.status).to eq(302)
          end
        end

        context 'with broker_agency_declined broker staff' do
          let(:baa_active) { true }
          let(:broker_staff_state) { 'broker_agency_declined' }

          it 'denies access' do
            consumer_role.update_attributes(identity_validation: 'na', application_validation: 'na')
            post :term_or_cancel, params: params, session: session_params
            expect(flash[:error]).to eq('Access not allowed for family_policy.create?, (Pundit policy)')
            expect(response.status).to eq(302)
          end
        end

        context 'with broker_agency_terminated broker staff' do
          let(:baa_active) { true }
          let(:broker_staff_state) { 'broker_agency_terminated' }

          it 'denies access' do
            consumer_role.update_attributes(identity_validation: 'na', application_validation: 'na')
            post :term_or_cancel, params: params, session: session_params
            expect(flash[:error]).to eq('Access not allowed for family_policy.create?, (Pundit policy)')
            expect(response.status).to eq(302)
          end
        end
      end
    end
  end
end
