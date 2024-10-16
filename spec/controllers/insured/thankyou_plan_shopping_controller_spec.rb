# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"

RSpec.describe Insured::PlanShoppingsController, :type => :controller, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"

  describe 'GET thankyou', :dbclean => :around_each do
    let!(:system_year) { Date.today.year }
    let!(:start_of_year) { Date.new(system_year) }
    let!(:person) { FactoryBot.create(:person, :with_consumer_role, dob: Date.new(system_year - 25, 1, 19)) }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:user) { FactoryBot.create(:user, person: person) }
    let(:session_variables) { { elected_aptc: elected_aptc, max_aptc: max_aptc, aptc_grants: double } }

    context '@pct value' do
      let(:max_aptc) { 300.00 }
      let(:aptc_value2) { 200.00 }
      let(:input_params) do
        {
          id: hbx_enrollment.id,
          plan_id: hbx_enrollment.product_id,
          elected_aptc: elected_aptc,
          market_kind: "individual"
        }
      end

      let!(:hbx_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          :with_silver_health_product,
                          :individual_unassisted,
                          effective_on: start_of_year.next_month,
                          family: family,
                          aasm_state: "shopping",
                          household: family.active_household,
                          coverage_kind: "health",
                          rating_area_id: rating_area.id)
      end

      let!(:hbx_enrollment_member) do
        FactoryBot.create(:hbx_enrollment_member, is_subscriber: true, hbx_enrollment: hbx_enrollment,
                                                  applicant_id: family.primary_applicant.id, coverage_start_on: start_of_year.next_month,
                                                  eligibility_date: start_of_year.next_month)
      end

      before do
        person.consumer_role.move_identity_documents_to_verified
        allow(TimeKeeper).to receive(:date_of_record).and_return(start_of_year)
        allow(EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature).to receive(:is_enabled).and_return(true)
        allow(::Operations::PremiumCredits::FindAptc).to receive(:new).and_return(
          double(
            call: double(
              success?: true,
              value!: aptc_value2
            )
          )
        )
        controller.instance_variable_set(:@max_aptc, max_aptc)
        controller.instance_variable_set(:@aptc_grants, double)
        allow_any_instance_of(UnassistedPlanCostDecorator).to receive(:total_premium).and_return(410)
        allow_any_instance_of(UnassistedPlanCostDecorator).to receive(:total_ehb_premium).and_return(393.76)
        sign_in(user)
        get :thankyou, params: input_params, session: session_variables
      end

      shared_examples "sets @pct correctly" do |elected_aptc_value, expected_pct|
        let(:elected_aptc) { elected_aptc_value }

        it "should set @pct to #{expected_pct}" do
          expect(response).to have_http_status(:success)
          expect(assigns(:pct)).to eq(expected_pct)
        end
      end

      context "when elected aptc is 0" do
        it_behaves_like "sets @pct correctly", 0.0, 100
      end

      context "when elected aptc is 50% of max_aptc" do
        it_behaves_like "sets @pct correctly", 150.0, 50
      end

      context "when elected aptc is 1$ of max_aptc" do
        it_behaves_like "sets @pct correctly", 1.0, 100
      end

      context "when elected aptc is 100% of max_aptc" do
        it_behaves_like "sets @pct correctly", 300.0, 100
      end
    end
  end
end