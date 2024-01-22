require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Products::QhpController, :type => :controller, dbclean: :around_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:person) {FactoryBot.create(:person)}
  let(:user) { FactoryBot.create(:user, person: person) }
  let(:family){ FactoryBot.create(:family, :with_primary_family_member_and_dependent) }
  let(:household){ family.active_household }
  let(:hbx_enrollment){ FactoryBot.create(:hbx_enrollment, :with_product, sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id,
                                           family: household.family,
                                           household: household,
                                           hbx_enrollment_members: [hbx_enrollment_member],
                                           coverage_kind: "health",
                                           external_enrollment: false,
                                           sponsored_benefit_id: sponsored_benefit.id,
                                           rating_area_id: rating_area.id)}
  let(:benefit_group) { current_benefit_package }
  let!(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile, benefit_group: current_benefit_package ) }
  let(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }
  let!(:employee_role) { FactoryBot.create(:employee_role, person: person, employer_profile: abc_profile, census_employee_id: census_employee.id) }
  let(:rate_schedule_date) {TimeKeeper.date_of_record}
  let(:dental_sponsored_benefit) { true }
  let(:product_kinds) { [:health, :dental] }
  let(:package_kind) { :single_product }
  let(:package) { initial_application.benefit_packages[0] }
  let(:health_product) do
    BenefitMarkets::Products::Product.where({
      :_type => /Health/,
      "application_period.min" => initial_application.benefit_packages[0].effective_period.min.beginning_of_year
    }).first
  end
  let(:dental_product) do
    BenefitMarkets::Products::Product.where({
      :_type => /Dental/,
      "application_period.min" => initial_application.benefit_packages[0].effective_period.min.beginning_of_year
    }).first
  end


  let(:shop_health_enrollment) { FactoryBot.create(:hbx_enrollment,
    family: family,
    household: family.active_household,
    product: health_product,
    employee_role_id: employee_role.id,
    sponsored_benefit_id: package.health_sponsored_benefit.id,
    benefit_sponsorship_id: benefit_sponsorship.id,
    sponsored_benefit_package_id: package.id,
    rating_area_id: rating_area.id
  )}

  let(:shop_dental_enrollment) { FactoryBot.create(:hbx_enrollment,
    family: family,
    household: family.active_household,
    product: dental_product,
    sponsored_benefit_id: package.dental_sponsored_benefit.id,
    benefit_sponsorship_id: benefit_sponsorship.id,
    sponsored_benefit_package_id: package.id,
    rating_area_id: rating_area.id
  )}

  let(:ivl_health_enrollment) { FactoryBot.create(:hbx_enrollment,
    household: family.active_household,
    coverage_kind: "health"
  )}

  let(:ivl_dental_enrollment) { FactoryBot.create(:hbx_enrollment,
    household: family.active_household,
    coverage_kind: "dental"
  )}

  after :all do
    DatabaseCleaner.clean
  end

  context 'GET comparison', :dbclean => :around_each do
    let(:input_params) do
      {
        standard_component_ids: ['11111111111111-01', '11111111111111-02'],
        hbx_enrollment_id: shop_health_enrollment.id,
        active_year: shop_health_enrollment.effective_on.year,
        market_kind: 'shop',
        coverage_kind: 'health'
      }
    end

    it "should return comparison of multiple plans" do
      sign_in(user)
      get :comparison, params: input_params
      expect(response).to have_http_status(:success)
    end
  end

  context "GET summary", :dbclean => :around_each do
    let(:qhp_cost_share_variance){ double("QhpCostShareVariance", :hios_plan_and_variant_id => "id") }
    let(:product) { double("Product") }
    let(:qhp_cost_share_variances) { [qhp_cost_share_variance] }
    let(:enrollment_plan_id) { shop_health_enrollment.plan_id }
    let(:dental_plan_id) { shop_dental_enrollment.plan_id }

    before do
      allow(Products::QhpCostShareVariance).to receive(:find_qhp_cost_share_variances).and_return(qhp_cost_share_variances)
    end

    it "should return summary of a plan for shop and coverage_kind as health" do
      allow(qhp_cost_share_variance).to receive(:product_for).with("aca_shop").and_return(product)
      sign_in(user)
      get :summary, params: {enrollment_plan_id: enrollment_plan_id, standard_component_id: "11111100001111-01", hbx_enrollment_id: shop_health_enrollment.id,
                             active_year: shop_health_enrollment.effective_on.year, market_kind: "shop", coverage_kind: "health"}
      expect(response).to have_http_status(:success)
      expect(assigns(:market_kind)).to eq "aca_shop"
      expect(assigns(:coverage_kind)).to eq "health"
    end

    it "should return summary of a plan for fehb and coverage_kind as health" do
      allow(qhp_cost_share_variance).to receive(:product_for).with("fehb").and_return(product)
      sign_in(user)
      get :summary, params: {standard_component_id: "11111100001111-01", hbx_enrollment_id: shop_health_enrollment.id, active_year: shop_health_enrollment.effective_on.year, market_kind: "fehb", coverage_kind: "health"}
      expect(response).to have_http_status(:success)
      expect(assigns(:market_kind)).to eq "fehb"
      expect(assigns(:coverage_kind)).to eq "health"
    end

    it "should return summary of a plan for shop and coverage_kind as dental" do
      allow(qhp_cost_share_variance).to receive(:product_for).with("aca_shop").and_return(product)
      allow(qhp_cost_share_variance).to receive(:hios_plan_and_variant_id=)
      sign_in(user)
      get :summary, params: {dental_plan_id: dental_plan_id, standard_component_id: "11111100001111-01", hbx_enrollment_id: shop_dental_enrollment.id,
                             active_year: shop_dental_enrollment.effective_on.year, market_kind: "shop", coverage_kind: "dental"}
      expect(response).to have_http_status(:success)
      expect(assigns(:market_kind)).to eq "aca_shop"
      expect(assigns(:coverage_kind)).to eq "dental"
    end

    it "should return summary of a plan for individual and coverage_kind as health" do
      allow(qhp_cost_share_variance).to receive(:product_for).with("individual").and_return(product)
      sign_in(user)
      get :summary, params: {enrollment_plan_id: enrollment_plan_id, standard_component_id: "11111100001111-01", hbx_enrollment_id: shop_health_enrollment.id,
                             active_year: shop_health_enrollment.effective_on.year, market_kind: "individual", coverage_kind: "health"}
      expect(response).to have_http_status(:success)
      expect(assigns(:market_kind)).to eq "individual"
      expect(assigns(:coverage_kind)).to eq "health"
    end

    it "should return summary of a plan for individual and coverage_kind as dental" do
      allow(qhp_cost_share_variance).to receive(:product_for).with("individual").and_return(product)
      allow(qhp_cost_share_variance).to receive(:hios_plan_and_variant_id=)
      sign_in(user)
      get :summary, params: {dental_plan_id: dental_plan_id, standard_component_id: "11111100001111-01", hbx_enrollment_id: shop_dental_enrollment.id,
                             active_year: shop_dental_enrollment.effective_on.year, market_kind: "individual", coverage_kind: "dental"}
      expect(response).to have_http_status(:success)
      expect(assigns(:market_kind)).to eq "individual"
      expect(assigns(:coverage_kind)).to eq "dental"
    end
  end

  context 'GET summary without HbxEnrollment BSON Id' do
    let(:input_params) do
      {
        standard_component_id: '11111100001111-01',
        active_year: '2015',
        market_kind: 'shop',
        coverage_kind: 'health'
      }
    end

    it 'returns 500 status code' do
      sign_in(user)
      get :summary, params: input_params
      expect(response).to have_http_status(500)
    end
  end

  context 'GET summary with invalid HbxEnrollment BSON Id' do
    let(:input_params) do
      {
        standard_component_id: '11111100001111-01',
        active_year: '2015',
        hbx_enrollment_id: '1234567890',
        market_kind: 'shop',
        coverage_kind: 'health'
      }
    end

    it 'returns 500 status code' do
      sign_in(user)
      get :summary, params: input_params
      expect(response).to have_http_status(500)
    end
  end
end
