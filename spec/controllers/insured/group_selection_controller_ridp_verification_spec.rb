# frozen_string_literal: true

RSpec.describe Insured::GroupSelectionController, type: :controller do
  before :all do
    DatabaseCleaner.clean
  end

  after :all do
    DatabaseCleaner.clean
  end

  let(:rating_area) { FactoryBot.create_default(:benefit_markets_locations_rating_area) }

  let(:user) { FactoryBot.create(:user, person: person) }
  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:consumer_role) { person.consumer_role }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

  let(:session_params) { { person_id: family.primary_person.id } }

  let(:hbx_enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      :individual_unassisted,
      :with_health_product,
      family: family,
      household: family.active_household,
      coverage_kind: 'health',
      effective_on: TimeKeeper.date_of_record.beginning_of_month,
      consumer_role: consumer_role,
      rating_area_id: rating_area.id
    )
  end

  let(:broker_person) { FactoryBot.create(:person) }
  let(:broker_role) { FactoryBot.create(:broker_role, person: broker_person) }
  let(:broker_user) { FactoryBot.create(:user, person: broker_person) }

  let(:broker_staff_person) { FactoryBot.create(:person) }
  let(:broker_staff) do
    FactoryBot.create(
      :broker_agency_staff_role,
      person: broker_staff_person,
      aasm_state: 'active',
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

  let(:broker_agency_account) do
    family.broker_agency_accounts.create!(
      benefit_sponsors_broker_agency_profile_id: broker_agency_id,
      writing_agent_id: broker_role.id,
      is_active: true,
      start_on: TimeKeeper.date_of_record
    )
  end

  let(:hbx_profile) do
    FactoryBot.create(
      :hbx_profile,
      :normal_ivl_open_enrollment,
      us_state_abbreviation: EnrollRegistry[:enroll_app].setting(:state_abbreviation).item,
      cms_id: "#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.upcase}0"
    )
  end

  before do
    broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
    broker_person.create_broker_agency_staff_role(
      benefit_sponsors_broker_agency_profile_id: broker_role.benefit_sponsors_broker_agency_profile_id
    )
    broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id, market_kind: :both)
    broker_role.approve!
    broker_agency_account
    broker_staff
    rating_area
    hbx_profile
    sign_in logged_in_user
  end

  describe "GET #new" do
    context 'with:
      - individual market family
      - legacy-verified RIDP
    ' do

      let(:params) do
        {
          person_id: person.id,
          consumer_role_id: consumer_role.id,
          change_plan: 'change_plan',
          shop_for_plans: 'shop_for_plans'
        }
      end

      let(:logged_in_user) { user }

      before :each do
        user.update_attributes!(:identity_final_decision_code => "acc")
      end

      it 'does not redirect to root_path with a flash message' do
        get :new, params: params, session: session_params
        expect(response).not_to redirect_to root_path
      end
    end

    context 'with:
      - individual market family
      - unverified RIDP
    ' do

      let(:params) do
        {
          person_id: person.id,
          consumer_role_id: consumer_role.id,
          change_plan: 'change_plan',
          shop_for_plans: 'shop_for_plans'
        }
      end

      context 'consumer logs into their own account' do
        let(:logged_in_user) { user }

        it 'redirects to root_path with a flash message' do
          get :new, params: params, session: session_params
          expect(response).to redirect_to root_path
          expect(flash[:error]).to eq('You must verify your identity before shopping for insurance.')
        end
      end

      context 'active associated certified broker logs into their own account' do
        let(:logged_in_user) { broker_user }

        it 'redirects to root_path with a flash message' do
          get :new, params: params, session: session_params
          expect(response).not_to redirect_to root_path
          expect(flash[:error]).not_to eq('You must verify your identity before shopping for insurance.')
        end
      end

      context 'active associated broker staff logs into their own account' do
        let(:logged_in_user) { broker_staff_user }

        it 'redirects to root_path with a flash message' do
          get :new, params: params, session: session_params
          expect(response).not_to redirect_to root_path
          expect(flash[:error]).not_to eq('You must verify your identity before shopping for insurance.')
        end
      end
    end
  end

  describe "POST #create" do
    context 'with:
      - individual market family
      - unverified RIDP
    ' do

      let(:params) do
        {
          person_id: person.id,
          consumer_role_id: consumer_role.id,
          change_plan: 'change_plan',
          market_kind: 'individual',
          enrollment_kind: 'sep',
          family_member_ids: family.family_members.pluck(:id)
        }
      end

      context 'consumer logs into their own account' do
        let(:logged_in_user) { user }

        it 'redirects to root_path with a flash message' do
          post :create, params: params, session: session_params
          expect(response).to redirect_to root_path
          expect(flash[:error]).to eq('You must verify your identity before shopping for insurance.')
        end
      end

      context 'active associated certified broker logs into their own account' do
        let(:logged_in_user) { broker_user }

        it 'redirects to root_path with a flash message' do
          post :create, params: params, session: session_params
          expect(response).not_to redirect_to root_path
          expect(flash[:error]).not_to eq('You must verify your identity before shopping for insurance.')
        end
      end

      context 'active associated broker staff logs into their own account' do
        let(:logged_in_user) { broker_staff_user }

        it 'redirects to root_path with a flash message' do
          post :create, params: params, session: session_params
          expect(response).not_to redirect_to root_path
          expect(flash[:error]).not_to eq('You must verify your identity before shopping for insurance.')
        end
      end
    end
  end

  describe "GET #terminate_confirm" do
    context 'with:
      - individual market family
      - unverified RIDP
    ' do

      let(:params) { { hbx_enrollment_id: hbx_enrollment.id } }

      context 'consumer logs into their own account' do
        let(:logged_in_user) { user }

        it 'redirects to root_path with a flash message' do
          get :terminate_confirm, params: params, session: session_params
          expect(response).to redirect_to root_path
          expect(flash[:error]).to eq('You must verify your identity before shopping for insurance.')
        end
      end

      context 'active associated certified broker logs into their own account' do
        let(:logged_in_user) { broker_user }

        it 'redirects to root_path with a flash message' do
          get :terminate_confirm, params: params, session: session_params
          expect(response).not_to redirect_to root_path
          expect(flash[:error]).not_to eq('You must verify your identity before shopping for insurance.')
        end
      end

      context 'active associated broker staff logs into their own account' do
        let(:logged_in_user) { broker_staff_user }

        it 'redirects to root_path with a flash message' do
          get :terminate_confirm, params: params, session: session_params
          expect(response).not_to redirect_to root_path
          expect(flash[:error]).not_to eq('You must verify your identity before shopping for insurance.')
        end
      end
    end
  end

  describe "POST #terminate" do
    context 'with:
      - individual market family
      - unverified RIDP
    ' do

      let(:params) { { term_date: TimeKeeper.date_of_record, hbx_enrollment_id: hbx_enrollment.id } }

      context 'consumer logs into their own account' do
        let(:logged_in_user) { user }

        it 'redirects to root_path with a flash message' do
          post :terminate, params: params, session: session_params
          expect(response).to redirect_to root_path
          expect(flash[:error]).to eq('You must verify your identity before shopping for insurance.')
        end
      end

      context 'active associated certified broker logs into their own account' do
        let(:logged_in_user) { broker_user }

        it 'redirects to root_path with a flash message' do
          post :terminate, params: params, session: session_params
          expect(response).not_to redirect_to root_path
          expect(flash[:error]).not_to eq('You must verify your identity before shopping for insurance.')
        end
      end

      context 'active associated broker staff logs into their own account' do
        let(:logged_in_user) { broker_staff_user }

        it 'redirects to root_path with a flash message' do
          post :terminate, params: params, session: session_params
          expect(response).not_to redirect_to root_path
          expect(flash[:error]).not_to eq('You must verify your identity before shopping for insurance.')
        end
      end
    end
  end

  describe "GET #edit_plan" do
    context 'with:
      - individual market family
      - unverified RIDP
    ' do

      let(:params) { { hbx_enrollment_id: hbx_enrollment.id, family_id: family.id } }

      context 'consumer logs into their own account' do
        let(:logged_in_user) { user }

        it 'redirects to root_path with a flash message' do
          get :edit_plan, params: params, session: session_params
          expect(response).to redirect_to root_path
          expect(flash[:error]).to eq('You must verify your identity before shopping for insurance.')
        end
      end
    end
  end

  describe "POST #term_or_cancel" do
    context 'with:
      - individual market family
      - unverified RIDP
    ' do

      let(:params) { { hbx_enrollment_id: hbx_enrollment.id, term_date: nil, term_or_cancel: 'cancel' } }

      context 'consumer logs into their own account' do
        let(:logged_in_user) { user }

        it 'redirects to root_path with a flash message' do
          post :term_or_cancel, params: params, session: session_params
          expect(response).to redirect_to root_path
          expect(flash[:error]).to eq('You must verify your identity before shopping for insurance.')
        end
      end

      context 'active associated certified broker logs into their own account' do
        let(:logged_in_user) { broker_user }

        it 'redirects to root_path with a flash message' do
          post :term_or_cancel, params: params, session: session_params
          expect(response).not_to redirect_to root_path
          expect(flash[:error]).not_to eq('You must verify your identity before shopping for insurance.')
        end
      end

      context 'active associated broker staff logs into their own account' do
        let(:logged_in_user) { broker_staff_user }

        it 'redirects to root_path with a flash message' do
          post :term_or_cancel, params: params, session: session_params
          expect(response).not_to redirect_to root_path
          expect(flash[:error]).not_to eq('You must verify your identity before shopping for insurance.')
        end
      end
    end
  end

  describe "POST #edit_aptc" do
    context 'with:
      - individual market family
      - unverified RIDP
    ' do

      let(:params) do
        {
          applied_pct_1: '0.39772',
          aptc_applied_total: 250.00,
          hbx_enrollment_id: hbx_enrollment.id.to_s
        }
      end

      context 'consumer logs into their own account' do
        let(:logged_in_user) { user }

        it 'redirects to root_path with a flash message' do
          post :edit_aptc, params: params, session: session_params
          expect(response).to redirect_to root_path
          expect(flash[:error]).to eq('You must verify your identity before shopping for insurance.')
        end
      end

      context 'active associated certified broker logs into their own account' do
        let(:logged_in_user) { broker_user }

        it 'redirects to root_path with a flash message' do
          post :edit_aptc, params: params, session: session_params
          expect(response).not_to redirect_to root_path
          expect(flash[:error]).not_to eq('You must verify your identity before shopping for insurance.')
        end
      end

      context 'active associated broker staff logs into their own account' do
        let(:logged_in_user) { broker_staff_user }

        it 'redirects to root_path with a flash message' do
          post :edit_aptc, params: params, session: session_params
          expect(response).not_to redirect_to root_path
          expect(flash[:error]).not_to eq('You must verify your identity before shopping for insurance.')
        end
      end
    end
  end
end
