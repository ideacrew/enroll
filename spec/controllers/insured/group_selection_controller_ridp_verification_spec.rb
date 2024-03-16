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

  describe "GET #new" do
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

      it 'redirects to root_path with a flash message' do
        sign_in user
        get :new, params: params, session: session_params
        expect(response).to redirect_to root_path
        expect(flash[:error]).to eq('You must verify your identity before shopping for insurance.')
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

      it 'redirects to root_path with a flash message' do
        rating_area
        sign_in user
        post :create, params: params, session: session_params
        expect(response).to redirect_to root_path
        expect(flash[:error]).to eq('You must verify your identity before shopping for insurance.')
      end
    end
  end

  describe "GET #terminate_confirm" do
    context 'with:
      - individual market family
      - unverified RIDP
    ' do

      let(:params) { { hbx_enrollment_id: hbx_enrollment.id } }

      it 'redirects to root_path with a flash message' do
        sign_in user
        get :terminate_confirm, params: params, session: session_params
        expect(response).to redirect_to root_path
        expect(flash[:error]).to eq('You must verify your identity before shopping for insurance.')
      end
    end
  end

  describe "POST #terminate" do
    context 'with:
      - individual market family
      - unverified RIDP
    ' do

      let(:params) { { term_date: TimeKeeper.date_of_record, hbx_enrollment_id: hbx_enrollment.id } }

      it 'redirects to root_path with a flash message' do
        sign_in user
        post :terminate, params: params, session: session_params
        expect(response).to redirect_to root_path
        expect(flash[:error]).to eq('You must verify your identity before shopping for insurance.')
      end
    end
  end

  describe "GET #edit_plan" do
    context 'with:
      - individual market family
      - unverified RIDP
    ' do

      let(:params) { { hbx_enrollment_id: hbx_enrollment.id, family_id: family.id } }

      it 'redirects to root_path with a flash message' do
        sign_in user
        get :edit_plan, params: params, session: session_params
        expect(response).to redirect_to root_path
        expect(flash[:error]).to eq('You must verify your identity before shopping for insurance.')
      end
    end
  end

  describe "POST #term_or_cancel" do
    context 'with:
      - individual market family
      - unverified RIDP
    ' do

      let(:params) { { hbx_enrollment_id: hbx_enrollment.id, term_date: nil, term_or_cancel: 'cancel' } }

      it 'redirects to root_path with a flash message' do
        sign_in user
        post :term_or_cancel, params: params, session: session_params
        expect(response).to redirect_to root_path
        expect(flash[:error]).to eq('You must verify your identity before shopping for insurance.')
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

      it 'redirects to root_path with a flash message' do
        sign_in user
        post :edit_aptc, params: params, session: session_params
        expect(response).to redirect_to root_path
        expect(flash[:error]).to eq('You must verify your identity before shopping for insurance.')
      end
    end
  end
end
