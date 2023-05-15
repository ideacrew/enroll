# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Insured::PlanShoppingsController, :type => :controller, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:person) {FactoryBot.create(:person, :with_family)}
  let(:user) { FactoryBot.create(:user, person: person) }
  let(:family){ FactoryBot.create(:family, :with_primary_family_member_and_dependent) }
  let(:family_members){ family.family_members.where(is_primary_applicant: false).to_a }
  let(:household){ family.active_household }
  let(:hbx_enrollment_member) do
    FactoryBot.build(:hbx_enrollment_member, is_subscriber: true,  applicant_id: family.family_members.first.id, coverage_start_on: TimeKeeper.date_of_record.beginning_of_month, eligibility_date: TimeKeeper.date_of_record.beginning_of_month)
  end
  let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
  let(:reference_plan) {double("Product")}
  let(:member_enrollment) {BenefitSponsors::Enrollments::MemberEnrollment.new(member_id: hbx_enrollment_member.id, product_price: BigDecimal(100),sponsor_contribution: BigDecimal(100))}
  let(:group_enrollment) {BenefitSponsors::Enrollments::GroupEnrollment.new(product: product, member_enrollments: [member_enrollment], product_cost_total: '')}
  let(:hbx_enrollment) do
    FactoryBot.create(:hbx_enrollment, :with_product, sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id,
                                                      family: household.family,
                                                      household: household,
                                                      hbx_enrollment_members: [hbx_enrollment_member],
                                                      coverage_kind: "health",
                                                      external_enrollment: false,
                                                      sponsored_benefit_id: sponsored_benefit.id,
                                                      rating_area_id: rating_area.id)
  end
  let(:benefit_group) { current_benefit_package }
  let(:usermailer) {double("UserMailer")}
  let!(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile, benefit_group: current_benefit_package) }
  let(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }
  let!(:employee_role) { FactoryBot.create(:employee_role, person: person, employer_profile: abc_profile, census_employee_id: census_employee.id) }
  let!(:sponsored_benefit) { initial_application.benefit_packages.first.sponsored_benefits.first }
  let(:rate_schedule_date) {TimeKeeper.date_of_record}
  let(:cost_calculator) { HbxEnrollmentSponsoredCostCalculator.new(hbx_enrollment) }

  before do
    EnrollRegistry[:extended_aptc_individual_agreement_message].feature.stub(:is_enabled).and_return(false)
  end

  context "POST checkout", :dbclean => :around_each do
    before do
      allow(BenefitMarkets::Products::Product).to receive(:find).with("plan_id").and_return(product)
      allow(HbxEnrollment).to receive(:find).with("hbx_id").and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:product=).with(product).and_return(true)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(hbx_enrollment).to receive(:can_select_coverage?).and_return true
      allow(hbx_enrollment).to receive(:is_special_enrollment?).and_return false
      allow(benefit_group).to receive(:reference_plan).and_return(:reference_plan)
      allow(PlanCostDecorator).to receive(:new).and_return(true)
      allow(hbx_enrollment).to receive(:save).and_return(true)
      allow(UserMailer).to receive(:plan_shopping_completed).and_return(usermailer)
      allow(usermailer).to receive(:deliver_now).and_return(true)
      allow(hbx_enrollment).to receive(:employee_role).and_return(employee_role)
      allow(employee_role).to receive(:hired_on).and_return(TimeKeeper.date_of_record + 10.days)

      sign_in user
    end

    it "should get person" do
      post :checkout, params: {id: "hbx_id", plan_id: "plan_id"}
      expect(assigns(:person)).to eq person
    end

    it "returns http success" do
      post :checkout, params: {id: "hbx_id", plan_id: "plan_id"}
      expect(response).to have_http_status(:redirect)
    end

    it "should delete pre_hbx_enrollment_id session" do
      session[:pre_hbx_enrollment_id] = "123"
      post :checkout, params: {id: "hbx_id", plan_id: "plan_id"}
      expect(response).to have_http_status(:redirect)
      expect(session[:pre_hbx_enrollment_id]).to eq nil
    end

    context "employee hire_on date greater than enrollment date" do
      it "fails" do
        post :checkout, params: {id: "hbx_id", plan_id: "plan_id"}
        expect(flash[:error]).to include("You are attempting to purchase coverage prior to your date of hire on record. Please contact your Employer for assistance")
      end
    end

    context "hbx_enrollment can not select_coverage" do
      let(:errors) { double }
      before :each do
        request.env["HTTP_REFERER"] = "/home"
        allow(employee_role).to receive(:hired_on).and_return(TimeKeeper.date_of_record - 10.days)
        allow(hbx_enrollment).to receive(:can_select_coverage?).and_return false
        allow(hbx_enrollment).to receive(:errors).and_return(errors)
        allow(errors).to receive(:full_messages).and_return("You can not keep an existing plan which belongs to previous plan year")
      end

      it "should redirect" do
        post :checkout, params: {id: "hbx_id", plan_id: "plan_id"}
        expect(response).to have_http_status(:redirect)
      end

      it "should get flash" do
        post :checkout, params: {id: "hbx_id", plan_id: "plan_id"}
        expect(flash[:error]).to include("You can not keep an existing plan which belongs to previous plan year")
      end
    end
  end

  context "GET receipt", :dbclean => :around_each do
    let(:member_group) { double("MEMBERGROUP")}

    before do
      allow(HbxEnrollment).to receive(:find).with("id").and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:sponsored_benefit).and_return(sponsored_benefit)
      allow(hbx_enrollment).to receive(:rating_area).and_return(rating_area)
      allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
      allow(hbx_enrollment).to receive(:product).and_return(product)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(hbx_enrollment).to receive(:employee_role).and_return(employee_role)
      allow(benefit_group).to receive(:reference_plan).and_return(reference_plan)
      allow(hbx_enrollment).to receive(:build_plan_premium).and_return(true)
      allow(hbx_enrollment).to receive(:census_employee).and_return(census_employee)
      allow(subject).to receive(:employee_mid_year_plan_change).and_return(true)
      allow(sponsored_benefit).to receive(:rate_schedule_date).and_return(rate_schedule_date)
      allow(HbxEnrollmentSponsoredCostCalculator).to receive(:new).with(hbx_enrollment).and_return(cost_calculator)
      allow(cost_calculator).to receive(:groups_for_products).with([product]).and_return([member_group])
    end

    it "returns http success" do
      sign_in(user)
      get :receipt, params: {id: "id"}
      expect(response).to have_http_status(:success)
    end

    it "should get employer_profile" do
      allow(hbx_enrollment).to receive(:employee_role_id).and_return(nil)
      allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
      allow(hbx_enrollment).to receive(:coverage_kind).and_return('health')
      allow(hbx_enrollment).to receive(:employer_profile).and_return(abc_profile)
      sign_in(user)
      get :receipt, params: {id: "id"}
      expect(assigns(:employer_profile)).to eq abc_profile
    end

    context "#send_receipt_emails" do
      context 'shop' do
        before do
          allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
          sign_in(user)
        end

        context 'when send_secure_purchase_confirmation_email enabled' do
          it 'should send secure message' do
            EnrollRegistry[:send_shop_secure_purchase_confirmation_email].feature.stub(:is_enabled).and_return(true)
            expect(person.inbox.messages.count).to eq(1)
            get :receipt, params: {id: "id"}
            expect(person.inbox.messages.count).to eq(2)
            expect(person.inbox.messages.last.subject).to eq("Your Enrollment Confirmation")
          end
        end

        context 'when send_secure_purchase_confirmation_email disabled' do
          it 'should not send secure message' do
            EnrollRegistry[:send_shop_secure_purchase_confirmation_email].feature.stub(:is_enabled).and_return(false)
            expect(person.inbox.messages.count).to eq(1)
            get :receipt, params: {id: "id"}
            expect(person.inbox.messages.count).to eq(1)
            expect(person.inbox.messages.last.subject).not_to eq("Your Enrollment Confirmation")
          end
        end
      end

      context 'ivl' do
        before do
          allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
          sign_in(user)
        end

        context 'when send_secure_purchase_confirmation_email enabled' do
          it 'should send secure message' do
            EnrollRegistry[:send_ivl_secure_purchase_confirmation_email].feature.stub(:is_enabled).and_return(true)
            expect(person.inbox.messages.count).to eq(1)
            get :receipt, params: {id: "id"}
            expect(person.inbox.messages.count).to eq(2)
            expect(person.inbox.messages.last.subject).to eq("Your Enrollment Confirmation")
          end
        end

        context 'when send_secure_purchase_confirmation_email disabled' do
          it 'should not send secure message' do
            EnrollRegistry[:send_ivl_secure_purchase_confirmation_email].feature.stub(:is_enabled).and_return(false)
            expect(person.inbox.messages.count).to eq(1)
            get :receipt, params: {id: "id"}
            expect(person.inbox.messages.count).to eq(1)
            expect(person.inbox.messages.last.subject).not_to eq("Your Enrollment Confirmation")
          end
        end
      end
    end
  end

  describe 'GET thankyou for set_aptcs_for_continuous_coverage', :dbclean => :around_each do
    let!(:system_year) { Date.today.year }
    let!(:start_of_year) { Date.new(system_year) }
    let!(:person10) { FactoryBot.create(:person, :with_consumer_role, dob: Date.new(system_year - 25, 1, 19)) }
    let!(:family10) { FactoryBot.create(:family, :with_primary_family_member, person: person10) }
    let!(:hbx_enrollment10) do
      FactoryBot.create(:hbx_enrollment,
                        :with_silver_health_product,
                        :individual_unassisted,
                        effective_on: start_of_year,
                        family: family10,
                        household: family10.active_household,
                        coverage_kind: "health",
                        rating_area_id: rating_area.id)
    end
    let!(:hbx_enrollment_member10) do
      FactoryBot.create(:hbx_enrollment_member, is_subscriber: true, hbx_enrollment: hbx_enrollment10, applicant_id: family10.primary_applicant.id,
                                                coverage_start_on: start_of_year, eligibility_date: start_of_year)
    end

    let!(:hbx_enrollment11) do
      FactoryBot.create(:hbx_enrollment,
                        :individual_unassisted,
                        effective_on: start_of_year.next_month,
                        family: family10,
                        product_id: hbx_enrollment10.product_id,
                        household: family10.active_household,
                        coverage_kind: "health",
                        rating_area_id: rating_area.id)
    end

    let!(:hbx_enrollment_member11) do
      FactoryBot.create(:hbx_enrollment_member, is_subscriber: true, hbx_enrollment: hbx_enrollment11,
                                                applicant_id: family10.primary_applicant.id, coverage_start_on: start_of_year.next_month,
                                                eligibility_date: start_of_year.next_month)
    end

    let(:input_params) do
      {
        id: hbx_enrollment11.id,
        plan_id: hbx_enrollment11.product_id,
        elected_aptc: aptc_value1
      }
    end

    let(:aptc_value1) { 300.00 }
    let(:aptc_value2) { 200.00 }

    before do
      allow(TimeKeeper).to receive(:date_of_record).and_return(start_of_year)
      EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature.stub(:is_enabled).and_return(true)

      allow(::Operations::PremiumCredits::FindAptc).to receive(:new).and_return(
        double(
          call: double(
            success?: true,
            value!: aptc_value2
          )
        )
      )
    end

    let(:session_variables) { { elected_aptc: aptc_value1, max_aptc: aptc_value1, aptc_grants: double } }

    context 'with continuous coverage' do
      before do
        controller.instance_variable_set(:@elected_aptc, aptc_value1)
        controller.instance_variable_set(:@max_aptc, aptc_value1)
        controller.instance_variable_set(:@aptc_grants, double)
        sign_in(user)
        get :thankyou, params: input_params, session: session_variables
      end

      it 'changes instance variables max_aptc and elected_aptc' do
        expect(response).to have_http_status(:success)
        expect(assigns(:elected_aptc)).to eq(aptc_value2)
        expect(assigns(:max_aptc)).to eq(aptc_value2)
      end

      it 'changes session variables elected_aptc and max_aptc' do
        expect(request.session[:elected_aptc]).to eq(aptc_value2)
        expect(request.session[:max_aptc]).to eq(aptc_value2)
      end
    end

    context 'with continuous coverage without APTC(UQHP)' do
      before do
        sign_in(user)
        get :thankyou, params: input_params, session: session_variables
      end

      it 'returns success' do
        expect(response).to have_http_status(:success)
        expect(assigns(:elected_aptc)).to be_zero
        expect(assigns(:max_aptc)).to be_zero
      end

      it 'does not change session variables elected_aptc and max_aptc' do
        expect(request.session[:elected_aptc]).to eq(aptc_value1)
        expect(request.session[:max_aptc]).to eq(aptc_value1)
      end
    end

    context 'without continuous coverage' do
      let(:product11) { FactoryBot.create(:benefit_markets_products_health_products_health_product, metal_level_kind: :silver) }

      before do
        controller.instance_variable_set(:@elected_aptc, aptc_value1)
        controller.instance_variable_set(:@max_aptc, aptc_value1)
        controller.instance_variable_set(:@aptc_grants, double)
        hbx_enrollment11.update_attributes!(product_id: product11.id)
        sign_in(user)
        get :thankyou, params: input_params, session: session_variables
      end

      it 'does not reset max_aptc and elected_aptc' do
        expect(response).to have_http_status(:success)
        expect(assigns(:elected_aptc)).to eq(aptc_value1)
        expect(assigns(:max_aptc)).to eq(aptc_value1)
      end

      it 'does not change session variables elected_aptc and max_aptc' do
        expect(request.session[:elected_aptc]).to eq(aptc_value1)
        expect(request.session[:max_aptc]).to eq(aptc_value1)
      end
    end
  end

  context "GET thankyou", :dbclean => :around_each do
    let(:member_group) { double("MEMBERGROUP")}
    let(:product_delegator) { double }

    before do
      allow(user).to receive(:person).and_return(person)
      allow(HbxEnrollment).to receive(:find).with("id").and_return(hbx_enrollment)
      allow(BenefitMarkets::Products::Product).to receive(:find).with("plan_id").and_return(product)
      allow(hbx_enrollment).to receive(:product).and_return(product)
      allow(hbx_enrollment).to receive(:rating_area).and_return(rating_area)
      allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
      allow(benefit_group).to receive(:reference_plan).and_return(reference_plan)
      allow(PlanCostDecorator).to receive(:new).and_return(true)
      allow(person).to receive(:primary_family).and_return(family)
      allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return(true)
      allow(hbx_enrollment).to receive(:employee_role).and_return(double)
      allow(hbx_enrollment).to receive(:is_special_enrollment?).and_return false
      allow(hbx_enrollment).to receive(:can_select_coverage?).and_return(true)
      allow(hbx_enrollment).to receive(:build_plan_premium).and_return(product_delegator)
      allow(product_delegator).to receive(:total_childcare_subsidy_amount).and_return(0.00)
      allow(hbx_enrollment).to receive(:update).and_return(true)
      allow(hbx_enrollment).to receive(:set_special_enrollment_period).and_return(true)
      allow(hbx_enrollment).to receive(:reset_dates_on_previously_covered_members).and_return(true)
      allow(hbx_enrollment).to receive(:sponsored_benefit).and_return(sponsored_benefit)
      allow(sponsored_benefit).to receive(:rate_schedule_date).and_return(rate_schedule_date)
      allow(HbxEnrollmentSponsoredCostCalculator).to receive(:new).with(hbx_enrollment).and_return(cost_calculator)
      allow(cost_calculator).to receive(:groups_for_products).with([product]).and_return([member_group])
      EnrollRegistry[:enrollment_product_date_match].feature.stub(:is_enabled).and_return(true)
    end

    it "returns http success" do
      sign_in(user)
      get :thankyou, params: {id: "id", plan_id: "plan_id"}
      expect(response).to have_http_status(:success)
    end

    it "when enrollment has change plan" do
      sign_in(user)
      get :thankyou, params: { id: "id", plan_id: "plan_id", change_plan: "rspec" }
      expect(assigns(:change_plan)).to eq "rspec"
    end

    it "when enrollment does not have change plan" do
      sign_in(user)
      allow(hbx_enrollment).to receive(:is_special_enrollment?).and_return true
      get :thankyou, params: { id: "id", plan_id: "plan_id" }
      expect(assigns(:change_plan)).to eq "change_plan"
    end

    it "should be enrollable" do
      sign_in(user)
      get :thankyou, params: {id: "id", plan_id: "plan_id"}
      expect(assigns(:enrollable)).to be_truthy
    end

    it "When enrollment kind receives" do
      sign_in(user)
      get :thankyou, params: { id: "id", plan_id: "plan_id", enrollment_kind: "shop" }
      expect(assigns(:enrollment_kind)).to eq "shop"
    end

    it "when is_special_enrollment " do
      sign_in(user)
      allow(hbx_enrollment).to receive(:is_special_enrollment?).and_return true
      get :thankyou, params: { id: "id", plan_id: "plan_id" }
      expect(assigns(:enrollment_kind)).to eq "sep"
    end

    it "when no special_enrollment" do
      sign_in(user)
      get :thankyou, params: { id: "id", plan_id: "plan_id" }
      expect(assigns(:enrollment_kind)).to eq ""
    end

    it "should be waivable" do
      sign_in(user)
      get :thankyou, params: {id: "id", plan_id: "plan_id"}
      expect(assigns(:waivable)).to be_truthy
    end

    it "should get employer_profile" do
      allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
      allow(hbx_enrollment).to receive(:coverage_kind).and_return('health')
      allow(hbx_enrollment).to receive(:employer_profile).and_return(abc_profile)
      allow(hbx_enrollment).to receive(:verify_and_reset_osse_subsidy_amount).and_return(true)
      sign_in(user)
      get :thankyou, params: {id: "id", plan_id: "plan_id"}
      expect(assigns(:employer_profile)).to eq abc_profile
    end

    it "returns http success as BROKER" do
      person = create(:person)
      FactoryBot.create(:family,:family_members => [{:is_primary_applicant => true, :is_active => true, :person_id => person.id}])
      current_broker_user = FactoryBot.create(:user, :roles => ['broker_agency_staff'],
                                                     :person => person)
      current_broker_user.person.broker_role = BrokerRole.new({:broker_agency_profile_id => 99})
      allow(session).to receive(:[]).and_return(person.id.to_s)
      sign_in(current_broker_user)
      get :thankyou, params: {id: "id", plan_id: "plan_id"}
      expect(response).to have_http_status(:success)
    end

    context "thankyou" do
      let(:member_group) { double("MEMBERGROUP")}
      let!(:person) { FactoryBot.create(:person)}
      let!(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person)}
      let(:primary) { family.primary_family_member }
      let(:dependents) { family.dependents }
      let!(:household) { FactoryBot.create(:household, family: family) }
      let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01') }

      let(:hbx_enrollment_member) do
        FactoryBot.build(:hbx_enrollment_member,
                         applicant_id: dependents.first.id)
      end
      let(:hbx_enrollment_member_1) do
        FactoryBot.build(:hbx_enrollment_member,
                         applicant_id: dependents.last.id)
      end
      let!(:hbx_enrollment_1) do
        FactoryBot.create(:hbx_enrollment,
                          family: family,
                          product: product,
                          household: family.active_household,
                          coverage_kind: "health",
                          kind: 'individual',
                          hbx_enrollment_members: [hbx_enrollment_member, hbx_enrollment_member_1],
                          aasm_state: 'coverage_selected')
      end
      let!(:hbx_enrollment_2) do
        FactoryBot.create(:hbx_enrollment,
                          family: family,
                          product: product,
                          kind: 'individual',
                          household: family.active_household,
                          coverage_kind: "health",
                          hbx_enrollment_members: [hbx_enrollment_member_1],
                          aasm_state: 'shopping')
      end

      before do
        allow(HbxEnrollment).to receive(:find).with("id").and_return(hbx_enrollment_2)
      end

      if EnrollRegistry.feature_enabled?(:existing_coverage_warning)
        it "when enrollment kind is ivl" do
          sign_in(user)
          get :thankyou, params: {id: "id", plan_id: "plan_id", market_kind: 'individual'}
          expect(assigns(:dependent_members)).to eq [hbx_enrollment_member_1]
        end

        it "when existing_coverage_warning setting is on is true & market kind is shop" do
          EnrollRegistry[:existing_coverage_warning].feature.stub(:is_enabled).and_return(true)
          sign_in(user)
          get :thankyou, params: {id: "id", plan_id: "plan_id", market_kind: "shop"}
          expect(assigns(:dependent_members)).to eq nil
        end
      end

      it "when enrollment kind is shop" do
        allow_any_instance_of(PlanSelection).to receive(:existing_coverage).and_return(nil)
        sign_in(user)
        get :thankyou, params: {id: "id", plan_id: "plan_id", market_kind: "shop"}
        expect(assigns(:dependent_members)).to eq nil
      end

      it "when existing_coverage_warning setting is on is false & market kind is shop" do
        allow_any_instance_of(PlanSelection).to receive(:existing_coverage).and_return(nil)
        EnrollRegistry[:existing_coverage_warning].feature.stub(:is_enabled).and_return(false)
        sign_in(user)
        get :thankyou, params: {id: "id", plan_id: "plan_id"}
        expect(assigns(:dependent_members)).to eq nil
      end
    end

    context "when not eligible to complete shopping" do
      before do
        allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return(false)
      end

      it "should not be enrollable" do
        sign_in(user)
        get :thankyou, params: {id: "id", plan_id: "plan_id"}
        expect(assigns(:enrollable)).to be_falsey
      end

      it "should not be waivable" do
        sign_in(user)
        get :thankyou, params: {id: "id", plan_id: "plan_id"}
        expect(assigns(:waivable)).to be_falsey
      end

      it "should update session" do
        sign_in(user)
        get :thankyou, params: {id: "id", plan_id: "plan_id", elected_aptc: "50"}
        expect(session[:elected_aptc]).to eq 50
      end
    end

    # context "for qualify_qle_notice" do
    #   it "should get error msg" do
    #     allow(hbx_enrollment).to receive(:can_select_coverage?).and_return false
    #     sign_in(user)
    #     get :thankyou, id: "id", plan_id: "plan_id"
    #     expect(flash[:error]).to include("In order to purchase benefit coverage, you must be in either an Open Enrollment or Special Enrollment period. ")
    #   end
    #
    #   it "should not get error msg" do
    #     allow(hbx_enrollment).to receive(:can_select_coverage?).and_return true
    #     sign_in(user)
    #     get :thankyou, id: "id", plan_id: "plan_id"
    #     expect(flash[:error]).to eq nil
    #   end
    # end
  end

  context 'GET thankyou  - reset coverage dates', :dbclean => :around_each do

    let(:person) {FactoryBot.create(:person, :with_active_consumer_role, :with_consumer_role)}
    let(:family) {FactoryBot.create(:family, :with_primary_family_member, :person => person)}
    let(:household) {FactoryBot.create(:household, family: family)}
    let(:year) {TimeKeeper.date_of_record.year}
    let(:effective_on) {Date.new(year, 3, 1)}
    let(:previous_enrollment_status) {'coverage_selected'}
    let(:terminated_on) {nil}
    let(:covered_individuals) {family.family_members}
    let(:newly_covered_individuals) {family.family_members}
    let(:start_on) {TimeKeeper.date_of_record.beginning_of_month}
    let(:qualifying_life_event_kind) {FactoryBot.create(:qualifying_life_event_kind)}
    let(:special_enrollment_period) do
      special_enrollment = person.primary_family.special_enrollment_periods.build({effective_on_kind: 'first_of_month'})
      special_enrollment.qualifying_life_event_kind = qualifying_life_event_kind
      special_enrollment.start_on = TimeKeeper.date_of_record.prev_day
      special_enrollment.end_on = TimeKeeper.date_of_record + 30.days
      special_enrollment.save
      special_enrollment
    end

    let(:product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        hios_id: '11111111122301-01',
                        csr_variant_id: '01',
                        metal_level_kind: :silver,
                        benefit_market_kind: :aca_individual,
                        application_period: Date.new(year, 1, 1)..Date.new(year, 12, 31))
    end

    let!(:previous_coverage) do
      FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                        enrollment_members: covered_individuals,
                        family: family,
                        household: family.latest_household,
                        coverage_kind: 'health',
                        effective_on: effective_on.beginning_of_year,
                        enrollment_kind: 'open_enrollment',
                        kind: 'individual',
                        consumer_role: person.consumer_role,
                        product: product,
                        aasm_state: previous_enrollment_status,
                        terminated_on: terminated_on)
    end

    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                        enrollment_members: newly_covered_individuals,
                        family: family,
                        household: family.latest_household,
                        coverage_kind: 'health',
                        effective_on: effective_on,
                        enrollment_kind: 'open_enrollment',
                        kind: 'individual',
                        consumer_role: person.consumer_role,
                        product: product)
    end

    it 'should update the member coverage start on for continuous coverage' do
      sign_in(user)
      get :thankyou, params: { id: hbx_enrollment.id, plan_id: product.id }
      hbx_enrollment.reload
      expect(hbx_enrollment.hbx_enrollment_members.first.coverage_start_on).to eq previous_coverage.hbx_enrollment_members.first.coverage_start_on
    end

    it "should redirect to the group selection page if IVL enrollment effective date doesn't match product dates" do
      EnrollRegistry[:enrollment_product_date_match].feature.stub(:is_enabled).and_return(false)
      hbx_enrollment.update_attributes!(effective_on: Date.new(year, 1, 1))
      product.update_attributes!(application_period: Date.new(year - 1, 1, 1)..Date.new(year - 1, 12, 31))
      sign_in(user)
      get :thankyou, params: {id: hbx_enrollment.id, plan_id: product.id, market_kind: 'individual'}
      expect(response).to redirect_to(new_insured_group_selection_path(person_id: person.id, change_plan: 'change_plan', hbx_enrollment_id: hbx_enrollment.id))
    end

    it "should render thank you page if SHOP enrollment effective date doesn't match product dates" do
      EnrollRegistry[:enrollment_product_date_match].feature.stub(:is_enabled).and_return(false)
      hbx_enrollment.update_attributes!(effective_on: Date.new(year, 1, 1))
      product.update_attributes!(application_period: Date.new(year - 1, 1, 1)..Date.new(year - 1, 12, 31))
      sign_in(user)
      get :thankyou, params: {id: hbx_enrollment.id, plan_id: product.id, market_kind: 'shop'}
      expect(response).to render_template('insured/plan_shoppings/thankyou.html.erb')
    end

    it "should render thank you page if enrollment effective date doesn't match product dates" do
      sign_in(user)
      get :thankyou, params: {id: hbx_enrollment.id, plan_id: product.id}
      expect(response).to render_template('insured/plan_shoppings/thankyou.html.erb')
    end
  end

  context "GET print_waiver", :dbclean => :around_each do
    it "should return hbx_enrollment to print waiver" do
      allow(user).to receive(:person).and_return(person)
      allow(HbxEnrollment).to receive(:find).with("id").and_return(hbx_enrollment)
      sign_in(user)
      get :print_waiver, params: {id: "id"}
      expect(response).to have_http_status(:success)
    end
  end

  context "POST terminate", :dbclean => :around_each do
    let(:coverage_start_on) {TimeKeeper.date_of_record.last_month.beginning_of_month}
    let(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment, :with_product,
                        sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id,
                        household: household,
                        family: household.family,
                        hbx_enrollment_members: [hbx_enrollment_member],
                        coverage_kind: "health",
                        effective_on: coverage_start_on,
                        external_enrollment: false,
                        sponsored_benefit_id: sponsored_benefit.id,
                        rating_area_id: rating_area.id)
    end

    let(:waiver_enrollment) do
      FactoryBot.create(:hbx_enrollment, :with_product,
                        sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id,
                        household: household,
                        family: household.family,
                        hbx_enrollment_members: [hbx_enrollment_member],
                        coverage_kind: "health",
                        external_enrollment: false,
                        sponsored_benefit_id: sponsored_benefit.id,
                        predecessor_enrollment_id: hbx_enrollment.id,
                        rating_area_id: rating_area.id)
    end
    let(:coverage_end_on) {TimeKeeper.date_of_record.end_of_month}

    before do
      allow(HbxEnrollment).to receive(:find).with("hbx_id").and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:employee_role_id).and_return(employee_role.id)
      allow(person).to receive(:primary_family).and_return(family)
      allow(hbx_enrollment).to receive(:rating_area).and_return(rating_area)
      allow(hbx_enrollment).to receive(:sponsored_benefit).and_return(sponsored_benefit)
      allow(sponsored_benefit).to receive(:rate_schedule_date).and_return(rate_schedule_date)
      allow(HbxEnrollmentSponsoredCostCalculator).to receive(:new).with(hbx_enrollment).and_return(cost_calculator)
      allow(waiver_enrollment).to receive(:parent_enrollment).and_return(hbx_enrollment)
      request.env["HTTP_REFERER"] = terminate_insured_plan_shopping_url(1)
      sign_in user
    end

    it "returns http success" do
      post :terminate, params: {id: "hbx_id"}
      expect(response).to be_redirect
    end

    it "goes back" do
      post :terminate, params: {id: "hbx_id"}
      expect(response).to have_http_status(:redirect)
    end

    it "should record termination submitted date on terminate of hbx_enrollment" do
      expect(hbx_enrollment.termination_submitted_on).to eq nil
      post :terminate, params: {id: "hbx_id", terminate_reason: "Because"}
      expect(hbx_enrollment.terminated_on).to eq coverage_end_on
      expect(hbx_enrollment.termination_submitted_on).to be_within(1.second).of TimeKeeper.datetime_of_record
      expect(response).to have_http_status(:redirect)
    end

    it "should create a new inactive enrollment" do
      post :terminate, params: {id: "hbx_id", terminate_reason: "Because"}
      hbx_enrollment.reload
      expect(hbx_enrollment.terminate_reason).to eq "Because"
    end

    context 'for terminate_date' do
      let(:terminate_date) { TimeKeeper.date_of_record.next_month.end_of_month }

      before do
        post :terminate, params: {id: 'hbx_id',
                                  terminate_reason: 'Because',
                                  terminate_date: terminate_date.to_s}
      end

      it 'terminated on date should be terminate_date' do
        expect(hbx_enrollment.terminated_on).to eq terminate_date
      end
    end

    context "errors terminating HBX Enrollment" do
      let(:terminate_date) { TimeKeeper.date_of_record - 1.week  }
      before do
        # active_plan_year = employee_role.employer_profile.show_plan_year
        # Let's make this blank!
        allow(hbx_enrollment.employee_role.employer_profile).to receive(:show_plan_year).and_return(nil)
        allow(hbx_enrollment.employee_role).to receive(:can_enroll_as_new_hire?).and_return(false)
        post(
          :terminate,
          params: {
            id: 'hbx_id',
            terminate_reason: 'Because',
            terminate_date: terminate_date.to_s
          }
        )
      end

      it "should redirect without throwing exceptions and show errors in alert message" do
        expect(flash[:alert]).to include("You may not enroll")
      end
    end
  end

  context "GET waive", :dbclean => :around_each do
    before :each do
      allow(HbxEnrollment).to receive(:find).with("hbx_id").and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:may_waive_coverage?).and_return(true)
      allow(hbx_enrollment).to receive(:waive_enrollment).and_return(true)
      allow(hbx_enrollment).to receive(:shopping?).and_return(true)
      sign_in user
    end

    it "should get success flash message" do
      allow(hbx_enrollment).to receive(:valid?).and_return(true)
      allow(hbx_enrollment).to receive(:save).and_return(true)
      allow(hbx_enrollment).to receive(:waive_coverage).and_return(true)
      allow(hbx_enrollment).to receive(:waiver_reason=).with("Because").and_return(true)
      allow(hbx_enrollment).to receive(:inactive?).and_return(true)
      get :waive, params: {id: "hbx_id", waiver_reason: "Because"}
      expect(flash[:notice]).to eq "Waive Coverage Successful"
      expect(response).to be_redirect
    end

    it "should get success flash mesage when enrollment is terminated" do
      allow(hbx_enrollment).to receive(:coverage_termination_pending?).and_return(true)
      allow(hbx_enrollment).to receive(:waiver_reason=).with("Because").and_return(true)
      allow(hbx_enrollment).to receive(:valid?).and_return(true)
      allow(hbx_enrollment).to receive(:inactive?).and_return(true)
      get :waive, params: {id: "hbx_id", waiver_reason: "Because"}
      expect(flash[:notice]).to eq "Waive Coverage Successful"
      expect(response).to be_redirect
    end

    it "#post enrollment termination" do
      allow(hbx_enrollment).to receive(:coverage_termination_pending?).and_return(true)
      allow(hbx_enrollment).to receive(:waiver_reason=).with("Because").and_return(true)
      allow(hbx_enrollment).to receive(:valid?).and_return(true)
      allow(hbx_enrollment).to receive(:inactive?).and_return(true)
      post :waive, params: {id: "hbx_id", waiver_reason: "Because"}
      expect(flash[:notice]).to eq "Waive Coverage Successful"
      expect(response).to be_redirect
    end

    it "should get failure flash message" do
      allow(hbx_enrollment).to receive(:waiver_reason=).with("Because").and_return(false)
      allow(hbx_enrollment).to receive(:valid?).and_return(false)
      allow(hbx_enrollment).to receive(:inactive?).and_return(false)
      get :waive, params: {id: "hbx_id", waiver_reason: "Because"}
      expect(flash[:alert]).to eq "Waive Coverage Failed"
      expect(response).to be_redirect
    end
  end

  context "GET show", :dbclean => :around_each do
    let(:product_1)   { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
    let(:product_2)   { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
    let(:product_3)   { FactoryBot.create(:benefit_markets_products_health_products_health_product) }
    let(:products) {[hbx_enrollment.sponsored_benefit.reference_product]}
    let(:coverage_kind){"health"}
    let(:cost_calculator) { HbxEnrollmentSponsoredCostCalculator.new(hbx_enrollment) }
    let(:consumer_person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:product_groups) { products }
    let(:family_group_enrollment) do
      BenefitSponsors::Enrollments::GroupEnrollment.new(
        member_enrollments: [],
        rate_schedule_date: '',
        coverage_start_on: '',
        previous_product: nil,
        product: products,
        rating_area: '',
        product_cost_total: ''
      )
    end
    let(:member_group) do
      ::BenefitSponsors::Members::MemberGroup.new(
        group_enrollment: [family_group_enrollment]
      )
    end
    let!(:update_sponsored_benefit) { sponsored_benefit.update_attributes(product_package_kind: "single_product") }

    before :each do
      allow(HbxEnrollmentSponsoredCostCalculator).to receive(:new).with(hbx_enrollment).and_return(cost_calculator)
      allow(HbxEnrollment).to receive(:find).with("hbx_id").and_return(hbx_enrollment)
      allow(hbx_enrollment).to receive(:household).and_return(household)
      allow(family).to receive(:family_members).and_return(family_members)
      allow(user).to receive(:person).and_return(person)
      allow(person).to receive(:primary_family).and_return(family)
      allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
      allow(hbx_enrollment).to receive(:kind).and_return("employer_sponsored")
      allow(hbx_enrollment).to receive(:consumer_role).and_return(consumer_person.consumer_role)
      allow(benefit_group).to receive(:plan_option_kind).and_return("single_plan")
      allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return(true)
      allow(hbx_enrollment).to receive(:effective_on).and_return(Date.new(2015))
      allow(hbx_enrollment).to receive(:family).and_return(family)
      allow(hbx_enrollment).to receive(:coverage_kind).and_return('health')
      allow(hbx_enrollment).to receive(:sponsored_benefit).and_return(sponsored_benefit)
      allow(hbx_enrollment).to receive(:employee_role).and_return employee_role
      allow(hbx_enrollment).to receive(:product).and_return(product_1)
      allow(sponsored_benefit).to receive(:rate_schedule_date).and_return(rate_schedule_date)
      allow(HbxEnrollmentSponsoredCostCalculator).to receive(:new).with(hbx_enrollment).and_return(cost_calculator)
      sign_in user
    end

    context "normal" do
      before :each do
        allow(cost_calculator).to receive(:groups_for_products).with(products).and_return(product_groups)
        allow_any_instance_of(Insured::PlanShoppingsController).to receive(:sort_member_groups).with(product_groups).and_return(member_group)
        allow(hbx_enrollment).to receive(:can_waive_enrollment?).and_return(true)
        get :show, params: {id: "hbx_id", market_kind: 'shop'}
      end

      it "should be success" do
        expect(response).to have_http_status(:success)
      end

      it "should be waivable" do
        expect(assigns(:waivable)).to be_truthy
      end

      it "should get the checkbook_url" do
        expect(assigns(:plan_comparison_checkbook_url)).to eq "http://checkbook_url"
      end
    end

    context "when sponsored_benefit package products are available" do
      before do
        allow(hbx_enrollment).to receive(:can_waive_enrollment?).and_return(true)
        sponsored_benefit_product_packages_product = hbx_enrollment.sponsored_benefit.products(hbx_enrollment.sponsored_benefit.rate_schedule_date).first
        sponsored_benefit_product_packages_product.update_attributes(hsa_eligibility: false)
        @original_product = BenefitMarkets::Products::Product.find(sponsored_benefit_product_packages_product.id)
        @original_product.update_attributes(hsa_eligibility: true)
        slug = Struct.new(:dob, :member_id)
        family_member = family_members.last
        age = ::BenefitSponsors::CoverageAgeCalculator.new.calc_coverage_age_for(slug.new(family_member.person.dob, family_member.person.id), nil, effective_period.max, {}, nil)
        allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(
          @original_product,
          effective_period.min,
          age,
          "R-DC001"
        ).and_return(100.00)
      end

      it "should fetch data from original products" do
        get :show, params: {id: "hbx_id", market_kind: 'shop'}
        expect(controller.instance_variable_get(:@member_groups).first.group_enrollment.product.hsa_eligibility).to eq(@original_product.hsa_eligibility)
      end
    end

    context "when not eligible to complete shopping" do
      let(:group_enrollment) {BenefitSponsors::Enrollments::GroupEnrollment.new(product: product, member_enrollments: [member_enrollment], product_cost_total: '')}

      before :each do
        allow(hbx_enrollment).to receive(:can_waive_enrollment?).and_return(false)
        allow(user).to receive(:person).and_return(person)
        allow(hbx_enrollment).to receive(:sponsored_benefit).and_return(sponsored_benefit)
        allow(person).to receive(:primary_family).and_return(family)
        allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
        allow(hbx_enrollment).to receive(:can_complete_shopping?).and_return(false)
        allow(hbx_enrollment).to receive(:coverage_kind).and_return('health')
        get :show, params: {id: "hbx_id"}
      end

      it "should not be waivable" do
        expect(assigns(:waivable)).to be_falsey
      end
    end

    # TODO: Fix this to run even if individual market not enabled
    if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
      context "when user has_active_consumer_role" do
        let(:tax_household) {double("TaxHousehold")}
        let(:family) { FactoryBot.build(:individual_market_family) }
        let(:person) {FactoryBot.create(:person, :with_family, :with_consumer_role)}
        let(:user) {double("user",person: person, has_hbx_staff_role?: true)}

        before do
          allow(hbx_enrollment).to receive(:coverage_kind).and_return('health')
          allow(hbx_enrollment).to receive(:is_shop?).and_return(false)
          allow(hbx_enrollment).to receive(:is_coverall?).and_return(false)
          allow(hbx_enrollment).to receive(:decorated_elected_plans).and_return([])
          EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature.stub(:is_enabled).and_return(false)
        end

        context "with tax_household" do
          before :each do
            allow(family).to receive(:latest_household).and_return(household)
            allow(household).to receive(:latest_active_tax_household_with_year).and_return tax_household
            allow(tax_household).to receive(:total_aptc_available_amount_for_enrollment).and_return(111)
            allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
            allow(person).to receive(:active_employee_roles).and_return []
            allow(person).to receive(:employee_roles).and_return []
            allow(hbx_enrollment).to receive(:kind).and_return 'individual'
            get :show, params: {id: "hbx_id", market_kind: "individual"}
          end

          it "should get max_aptc" do
            expect(assigns(:max_aptc)).to eq 111
          end

          it "should get default selected_aptc_pct" do
            percentage = EnrollRegistry[:enroll_app].setting(:default_aptc_percentage).item
            expect(assigns(:elected_aptc)).to eq (111 * percentage) / 100
          end
        end

        context "without tax_household" do
          before :each do
            allow(household).to receive(:latest_active_tax_household_with_year).and_return nil
            allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
            allow(person).to receive(:active_employee_roles).and_return []
            allow(person).to receive(:employee_roles).and_return []
            get :show, params: {id: "hbx_id"}
          end

          # it "should get max_aptc" do
          #   expect(session[:max_aptc]).to eq 0
          # end
          #
          # it "should get default selected_aptc" do
          #   expect(session[:elected_aptc]).to eq 0
          # end
        end

        context "without tax_household when has aptc session" do
          before :each do
            allow(household).to receive(:latest_active_tax_household_with_year).and_return nil
            allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
            allow(person).to receive(:active_employee_roles).and_return []
            allow(person).to receive(:employee_roles).and_return []
            session[:max_aptc] = 100
            session[:elected_aptc] = 80
            get :show, params: {id: "hbx_id"}
          end

          # it "should get max_aptc" do
          #   expect(session[:max_aptc]).to eq 0
          # end
          #
          # it "should get default selected_aptc" do
          #   expect(session[:elected_aptc]).to eq 0
          # end
        end

        context "with tax_household and plan shopping in shop market" do
          before :each do
            allow(household).to receive(:latest_active_tax_household_with_year).and_return tax_household
            allow(tax_household).to receive(:total_aptc_available_amount_for_enrollment).and_return(111)
            allow(family).to receive(:enrolled_hbx_enrollments).and_return([])
            allow(person).to receive(:active_employee_roles).and_return []
            allow(person).to receive(:employee_roles).and_return []
            allow(hbx_enrollment).to receive(:coverage_kind).and_return 'health'
            allow(hbx_enrollment).to receive(:kind).and_return 'shop'
            allow_any_instance_of(Services::CheckbookServices::PlanComparision).to receive(:generate_url).and_return("http://temp.url")
            get :show, params: {id: "hbx_id"}
          end

          # it "should get max_aptc" do
          #   expect(session[:max_aptc]).to eq 0
          # end
          #
          # it "should get default selected_aptc_pct" do
          #   expect(session[:elected_aptc]).to eq 0
          # end
        end
      end
    end
  end

  context "GET show for IVL", :dbclean => :around_each do
    let(:user)  { FactoryBot.create(:user, person: person1) }
    let(:person1) { FactoryBot.create(:person, :with_active_consumer_role, :with_consumer_role)}
    let(:family1) { FactoryBot.create(:family, :with_primary_family_member, :person => person1)}

    context "for nil rating area" do
      let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family1, household: family1.active_household, consumer_role_id: person1.consumer_role.id, kind: 'individual', product_id: product.id)}

      before :each do
        allow(EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model)).to receive(:item).and_return('county')
        allow(EnrollRegistry[:enroll_app].setting(:rating_areas)).to receive(:item).and_return('county')
        ::BenefitMarkets::Locations::RatingArea.all.update_all(covered_states: nil)
        sign_in user
        person1.addresses.update_all(county: nil)
        get :show, params: {id: hbx_enrollment.id, market_kind: "individual"}
      end

      it "should redirect to family home page" do
        expect(response).to have_http_status(:redirect)
        expect(flash[:error]).to eq l10n("insured.out_of_state_error_message")
      end
    end
  end

  context 'GET show for IVL  - reset coverage dates', :dbclean => :around_each do
    let(:person) {FactoryBot.create(:person, :with_active_consumer_role, :with_consumer_role)}
    let(:family) {FactoryBot.create(:family, :with_primary_family_member, :person => person)}
    let(:household) {FactoryBot.create(:household, family: family)}
    let(:year) {TimeKeeper.date_of_record.year}
    let(:effective_on) {Date.new(year, 3, 1)}
    let(:previous_enrollment_status) {'coverage_selected'}
    let(:terminated_on) {nil}
    let(:covered_individuals) {family.family_members}
    let(:newly_covered_individuals) {family.family_members}
    let(:start_on) {TimeKeeper.date_of_record.beginning_of_month}
    let(:qualifying_life_event_kind) {FactoryBot.create(:qualifying_life_event_kind)}
    let(:special_enrollment_period) do
      special_enrollment = person.primary_family.special_enrollment_periods.build({effective_on_kind: 'first_of_month'})
      special_enrollment.qualifying_life_event_kind = qualifying_life_event_kind
      special_enrollment.start_on = TimeKeeper.date_of_record.prev_day
      special_enrollment.end_on = TimeKeeper.date_of_record + 30.days
      special_enrollment.save
      special_enrollment
    end

    let(:product) do
      FactoryBot.create(:benefit_markets_products_health_products_health_product,
                        hios_id: '11111111122301-01',
                        csr_variant_id: '01',
                        metal_level_kind: :silver,
                        benefit_market_kind: :aca_individual,
                        application_period: Date.new(year, 1, 1)..Date.new(year, 12, 31))
    end

    let!(:previous_coverage) do
      FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                        enrollment_members: covered_individuals,
                        family: family,
                        household: family.latest_household,
                        coverage_kind: 'health',
                        effective_on: effective_on.beginning_of_year,
                        enrollment_kind: 'open_enrollment',
                        kind: 'individual',
                        consumer_role: person.consumer_role,
                        product: product,
                        aasm_state: previous_enrollment_status,
                        terminated_on: terminated_on,
                        rating_area_id: rating_area.id)
    end

    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                        enrollment_members: newly_covered_individuals,
                        family: family,
                        household: family.latest_household,
                        coverage_kind: 'health',
                        effective_on: effective_on,
                        enrollment_kind: 'open_enrollment',
                        kind: 'individual',
                        consumer_role: person.consumer_role,
                        product: product,
                        rating_area_id: rating_area.id)
    end

    it 'should update the member coverage start on' do
      sign_in(user)
      allow_any_instance_of(HbxEnrollment).to receive(:decorated_elected_plans).and_return([])
      hbx_enrollment.hbx_enrollment_members.update_all(coverage_start_on: previous_coverage.effective_on)
      get :show, params: {id: hbx_enrollment.id, market_kind: "individual"}
      hbx_enrollment.reload
      expect(hbx_enrollment.hbx_enrollment_members.first.coverage_start_on).to eq hbx_enrollment.effective_on
    end
  end


  if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
    describe "plan_selection_callback" do
      let(:coverage_kind){"health"}
      let(:market_kind){"individual"}
      let(:person) { FactoryBot.create(:person, :with_active_consumer_role, :with_consumer_role) }
      let(:user)  { FactoryBot.create(:user, person: person) }
      let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
      let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual) }
      let(:year) { product.application_period.min.year }
      let(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, kind: 'individual', effective_on: TimeKeeper.date_of_record.beginning_of_month.to_date, product_id: product.id) }

      context "When a callback is received" do
        before do
          sign_in user
          get :plan_selection_callback, params: { id: hbx_enrollment.id, hios_id: product.hios_id, year: year, market_kind: market_kind, coverage_kind: coverage_kind }
        end

        it "should assign market kind and coverage_kind" do
          expect(assigns(:market_kind)).to be_truthy
          expect(assigns(:coverage_kind)).to be_truthy
        end
      end
    end
  end
end
