# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Insured::PlanShoppingsController, type: :controller, dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  after :all do
    DatabaseCleaner.clean
  end

  describe 'POST #checkout' do
    let(:rating_area) { FactoryBot.create_default(:benefit_markets_locations_rating_area) }
    let(:user) { FactoryBot.create(:user, person: person) }
    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:consumer_role) { person.consumer_role }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:session_params) { { person_id: family.primary_person.id } }

    let(:input_params) do
      {
        id: checkout_enrollment.id,
        plan_id: checkout_enrollment.product.id,
        market_kind: checkout_enrollment.kind,
        coverage_kind: checkout_enrollment.coverage_kind,
        enrollment_kind: checkout_enrollment.kind,
        thankyou_page_agreement_terms: thankyou_page_agreement_terms
      }
    end

    before do
      sign_in user
      post :checkout, params: input_params, session: session_params
    end

    context 'for individual market enrollment' do
      let(:checkout_enrollment) do
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

      context 'with agreed thankyou_page_agreement_terms' do
        let(:thankyou_page_agreement_terms) { 'agreed' }

        it 'redirects to root as pundit authorization failed' do
          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to eq('Access not allowed for hbx_enrollment_policy.checkout?, (Pundit policy)')
        end
      end

      context 'with disagreed thankyou_page_agreement_terms' do
        let(:thankyou_page_agreement_terms) { 'disagreed' }

        it 'redirects to fallback location root_path' do
          expect(response).to redirect_to(root_path)
          expect(flash[:error]).to eq(l10n('insured.plan_shopping.thankyou.agreement_terms_conditions'))
        end
      end
    end
  end
end
