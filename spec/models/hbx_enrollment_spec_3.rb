# frozen_string_literal: true

require 'rails_helper'
require 'aasm/rspec'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require File.join(Rails.root, 'spec/shared_contexts/dchbx_product_selection')

describe HbxEnrollment, "reinstate and change end date", type: :model, :dbclean => :around_each do
  before do
    allow(::Operations::Products::ProductOfferedInServiceArea).to receive(:new).and_return(double(call: double(:success? => true)))
  end

  describe '#reinstate' do
    let(:family)        { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let!(:person)       { FactoryBot.create(:person, :with_consumer_role) }
    let!(:hbx_profile) do
      FactoryBot.create(:hbx_profile,
                        :normal_ivl_open_enrollment,
                        coverage_year: Date.today.year - 1)
    end

    let(:enrollment)    do
      FactoryBot.create(:hbx_enrollment, :with_health_product,
                        family: family,
                        coverage_kind: "health",
                        effective_on: TimeKeeper.date_of_record.last_year.beginning_of_year,
                        enrollment_kind: "open_enrollment",
                        kind: "individual",
                        aasm_state: "coverage_terminated",
                        consumer_role_id: person.consumer_role.id,
                        terminated_on: TimeKeeper.date_of_record.last_year + 6.months)
    end
    context 'product not offered in latest service area' do
      before do
        allow(::Operations::Products::ProductOfferedInServiceArea).to receive(:new).and_return(double(call: double(:success? => false)))
      end

      it 'returns false' do
        expect(enrollment.reinstate).to eq false
      end
    end

    context 'product offered in latest service area' do

      it 'returns enrollment' do
        expect(enrollment.reinstate.class).to eq HbxEnrollment
      end
    end
  end

  describe "reinstate aptc enrollment" do
    before :all do
      TimeKeeper.set_date_of_record_unprotected!(Date.new((Date.today.year - 1), 6, 1))
    end

    let!(:site_key) { EnrollRegistry[:enroll_app].setting(:site_key).item.upcase }
    let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
    let!(:family)        { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person) }
    let!(:person)       { FactoryBot.create(:person, :with_consumer_role) }
    let!(:address) { family.primary_person.rating_address }
    let!(:effective_date) { TimeKeeper.date_of_record.beginning_of_year }
    let!(:application_period) { effective_date.beginning_of_year..effective_date.end_of_year }
    let!(:rating_area) do
      ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: effective_date) || FactoryBot.create_default(:benefit_markets_locations_rating_area, active_year: effective_date.year)
    end
    let!(:service_area) do
      ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: effective_date).first || FactoryBot.create_default(:benefit_markets_locations_service_area, active_year: effective_date.year)
    end

    let!(:product) do
      prod =
        FactoryBot.create(
          :benefit_markets_products_health_products_health_product,
          :with_issuer_profile,
          :silver,
          benefit_market_kind: :aca_individual,
          kind: :health,
          application_period: application_period,
          service_area: service_area,
          csr_variant_id: '01'
        )
      prod.premium_tables = [premium_table]
      prod.save
      prod
    end

    let!(:premium_table)        { build(:benefit_markets_products_premium_table, effective_period: application_period, rating_area: rating_area) }
    let!(:tax_household_group) do
      family.tax_household_groups.create!(
        assistance_year: TimeKeeper.date_of_record.year,
        source: 'Admin',
        start_on: TimeKeeper.date_of_record.beginning_of_year,
        tax_households: [
          FactoryBot.build(:tax_household, household: family.active_household)
        ]
      )
    end

    let!(:tax_household) do
      tax_household_group.tax_households.first
    end

    let!(:eligibility_determination) do
      determination = family.create_eligibility_determination(effective_date: TimeKeeper.date_of_record.beginning_of_year)
      determination.grants.create(
        key: "AdvancePremiumAdjustmentGrant",
        value: yearly_expected_contribution,
        start_on: TimeKeeper.date_of_record.beginning_of_year,
        end_on: TimeKeeper.date_of_record.end_of_year,
        assistance_year: TimeKeeper.date_of_record.year,
        member_ids: family.family_members.map(&:id).map(&:to_s),
        tax_household_id: tax_household.id
      )

      determination
    end

    let!(:aptc_grant) { eligibility_determination.grants.first }
    let!(:yearly_expected_contribution) { 125.00 * 12 }
    let!(:slcsp_info) do
      OpenStruct.new(
        households: [OpenStruct.new(
          household_id: aptc_grant.tax_household_id,
          household_benchmark_ehb_premium: benchmark_premium,
          members: family.family_members.collect do |fm|
            OpenStruct.new(
              family_member_id: fm.id.to_s,
              relationship_with_primary: fm.primary_relationship,
              date_of_birth: fm.dob,
              age_on_effective_date: fm.age_on(TimeKeeper.date_of_record)
            )
          end
        )]
      )
    end

    let!(:primary_bp) { 500.00 }
    let!(:benchmark_premium) { primary_bp }
    let(:dependents) { family.dependents }
    let(:hbx_en_members) do
      dependents.collect do |dependent|
        FactoryBot.build(:hbx_enrollment_member,
                         applicant_id: dependent.id)
      end
    end

    let!(:enrollment) do
      FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :individual_assisted, family: family, product: product, consumer_role_id: person.consumer_role.id, rating_area_id: rating_area.id, hbx_enrollment_members: hbx_en_members)
    end
    let!(:thhm_enrollment_members) do
      enrollment.hbx_enrollment_members.collect do |member|
        FactoryBot.build(:tax_household_member_enrollment_member, hbx_enrollment_member_id: member.id, family_member_id: member.applicant_id, tax_household_member_id: "123")
      end
    end
    let!(:thhe) do
      FactoryBot.create(:tax_household_enrollment, enrollment_id: enrollment.id, tax_household_id: tax_household.id,
                                                   health_product_hios_id: enrollment.product.hios_id,
                                                   dental_product_hios_id: nil, tax_household_members_enrollment_members: thhm_enrollment_members)
    end

    before do
      allow(::Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts).to receive(:new).and_return(
        double('IdentifySlcspWithPediatricDentalCosts',
               call: double(:value! => slcsp_info, :success? => true))
      )
      effective_on = hbx_profile.benefit_sponsorship.current_benefit_period.start_on
      enrollment.update_attributes(effective_on: Date.new(effective_on.year, 1, 1), aasm_state: "coverage_terminated", terminated_on: Date.new(effective_on.year,5,31))
      hbx_profile.benefit_sponsorship.benefit_coverage_periods.each {|bcp| bcp.update_attributes!(slcsp_id: product.id)}
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(product, effective_on, person.age_on(Date.today), "R-#{site_key}001", 'N').and_return(679.8)
      cr1 = FactoryBot.build(:consumer_role, :contact_method => "Paper Only")
      family.family_members[1].person.consumer_role = cr1
      cr2 = FactoryBot.build(:consumer_role, :contact_method => "Paper Only")
      family.family_members[2].person.consumer_role = cr2
      family.save!
      EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature.stub(:is_enabled).and_return(true)
    end

    context "success" do
      before do
        allow(UnassistedPlanCostDecorator).to receive(:new).and_return(double(total_ehb_premium: 1500, total_premium: 1600))
      end

      it "should create tax household enrollment" do
        reinstate_enrollment = enrollment.reinstate

        expect(TaxHouseholdEnrollment.where(enrollment_id: reinstate_enrollment.id).present?).to be_truthy
      end

      it "should not have same bson id" do
        reinstate_enrollment = enrollment.reinstate

        expect(TaxHouseholdEnrollment.where(enrollment_id: reinstate_enrollment.id).first.id).not_to be thhe.id
      end

      it "should not have same tax household enrollment id"  do
        reinstate_enrollment = enrollment.reinstate

        expect(TaxHouseholdEnrollment.where(enrollment_id: reinstate_enrollment.id).first.enrollment_id).not_to be thhe.enrollment_id
      end
    end

    context 'when osse eligibility changed' do

      before do
        enrollment.update(applied_aptc_amount: 750, eligible_child_care_subsidy: eligible_child_care_subsidy)

        allow_any_instance_of(UnassistedPlanCostDecorator).to receive(:total_premium).and_return(1600)
        allow_any_instance_of(UnassistedPlanCostDecorator).to receive(:total_ehb_premium).and_return(1500)
        allow_any_instance_of(UnassistedPlanCostDecorator).to receive(:total_aptc_amount).and_return(750)
      end

      context "when termed enrollment has osse subsidy" do
        let(:eligible_child_care_subsidy) { 850.0 }

        before do
          allow_any_instance_of(UnassistedPlanCostDecorator).to receive(:ivl_osse_eligible?).and_return(false)
        end

        it 'should have same amount of subsidy on reinstated enrollment' do
          reinstate_enrollment = enrollment.reinstate

          expect(reinstate_enrollment.eligible_child_care_subsidy.to_f).to eq eligible_child_care_subsidy
          expect(reinstate_enrollment.total_employee_cost.to_f).to eq 0.0
        end
      end

      context "when termed enrollment has no osse subsidy" do
        let(:eligible_child_care_subsidy) { 0.0 }

        before do
          allow_any_instance_of(UnassistedPlanCostDecorator).to receive(:ivl_osse_eligible?).and_return(true)
        end

        it 'should not have subsidy on reinstated enrollment' do
          reinstate_enrollment = enrollment.reinstate
          expect(reinstate_enrollment.eligible_child_care_subsidy.to_f).to eq eligible_child_care_subsidy
          expect(reinstate_enrollment.total_employee_cost.to_f).to eq 850.0
        end
      end
    end

    after do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end
  end

  context "Terminated enrollment re-instatement" do
    let(:current_date) { Date.new(TimeKeeper.date_of_record.year, 6, 1) }
    let(:effective_on_date)         { Date.new(TimeKeeper.date_of_record.year, 3, 1) }
    let(:terminated_on_date)        {effective_on_date + 10.days}

    before do
      TimeKeeper.set_date_of_record_unprotected!(current_date)
    end

    after do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    context "for Individual market" do
      let(:person) { FactoryBot.create(:person, :with_consumer_role)}
      let(:ivl_family)        { FactoryBot.create(:family, :with_primary_family_member, person: person) }
      let!(:hbx_profile) { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period, coverage_year: TimeKeeper.date_of_record.year) }

      let(:consumer_role) { person.consumer_role }
      let(:ivl_enrollment)    do
        FactoryBot.create(:hbx_enrollment, :with_health_product,
                          family: ivl_family,
                          household: ivl_family.latest_household,
                          coverage_kind: "health",
                          effective_on: effective_on_date,
                          enrollment_kind: "open_enrollment",
                          kind: "individual",
                          aasm_state: "coverage_terminated",
                          consumer_role_id: consumer_role.id,
                          terminated_on: terminated_on_date)
      end

      it "should re-instate enrollment" do
        ivl_enrollment.reinstate
        reinstated_enrollment = HbxEnrollment.where(family_id: ivl_family.id).detect(&:coverage_selected?)

        expect(reinstated_enrollment.present?).to be_truthy
        expect(reinstated_enrollment.workflow_state_transitions.where(:to_state => 'coverage_reinstated').present?).to be_truthy
        expect(reinstated_enrollment.effective_on).to eq terminated_on_date.next_day
      end

      it "when feature enabled reinstate_nonpayment_ivl_enrollment, reset termination reason on reinstate" do
        consumer_role.update!(aasm_state: 'fully_verified')
        members = FactoryBot.build(:hbx_enrollment_member,
                                   applicant_id: ivl_family.primary_family_member.id,
                                   hbx_enrollment: ivl_enrollment, is_subscriber: true,
                                   coverage_start_on: ivl_enrollment.effective_on,
                                   eligibility_date: ivl_enrollment.effective_on, tobacco_use: 'Y')
        ivl_enrollment.update_attributes(terminate_reason: HbxEnrollment::TermReason::NON_PAYMENT, hbx_enrollment_members: [members])
        EnrollRegistry[:reinstate_nonpayment_ivl_enrollment].feature.stub(:is_enabled).and_return(true)

        ivl_enrollment.reinstate
        reinstated_enrollment = HbxEnrollment.where(family_id: ivl_family.id).detect(&:coverage_selected?)
        ivl_enrollment.reload
        expect(ivl_enrollment.terminate_reason).to be_nil
        expect(reinstated_enrollment.present?).to be_truthy
        expect(reinstated_enrollment.workflow_state_transitions.where(:to_state => 'coverage_reinstated').present?).to be_truthy
        expect(reinstated_enrollment.effective_on).to eq terminated_on_date.next_day
      end
    end

    context "for SHOP market" do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"

      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
      let(:effective_on) { current_effective_date }
      let(:hired_on) { TimeKeeper.date_of_record - 3.months }
      let(:employee_created_at) { hired_on }
      let(:employee_updated_at) { employee_created_at }

      let(:person) {FactoryBot.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789')}
      let(:shop_family) {FactoryBot.create(:family, :with_primary_family_member)}
      let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
      let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}

      let(:aasm_state) { :active }
      let(:census_employee) do
        create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package, hired_on: hired_on, created_at: employee_created_at,
                                                          updated_at: employee_updated_at)
      end
      let(:employee_role) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: census_employee.hired_on, census_employee_id: census_employee.id) }
      let(:enrollment_kind) { "open_enrollment" }
      let(:special_enrollment_period_id) { nil }
      let!(:shop_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          coverage_kind: "health",
                          family: shop_family,
                          effective_on: effective_on,
                          enrollment_kind: enrollment_kind,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: current_benefit_package.id,
                          sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                          employee_role_id: employee_role.id,
                          product: sponsored_benefit.reference_product,
                          benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
      end

      before do
        census_employee.update_attributes(employee_role_id: employee_role.id)
        census_employee.terminate_employment(effective_on + 1.days)
        shop_enrollment.reload
        census_employee.reload
      end

      it "should have terminated enrollment & cenuss employee" do
        expect(shop_enrollment.coverage_termination_pending?).to be_truthy
        expect(census_employee.employee_termination_pending?).to be_truthy
      end

      context 'when re-instated' do
        before do
          census_employee.terminate_employee_role!
          shop_enrollment.reinstate
        end

        it "should have re-instate enrollment" do
          reinstated_enrollment = HbxEnrollment.where(family_id: shop_family.id).detect(&:coverage_enrolled?)

          expect(reinstated_enrollment.present?).to be_truthy
          expect(reinstated_enrollment.workflow_state_transitions.where(:to_state => 'coverage_reinstated').present?).to be_truthy
          expect(reinstated_enrollment.effective_on).to eq shop_enrollment.terminated_on.next_day
        end

        it 'should re-instate census employee' do
          census_employee.reload
          expect(census_employee.employee_role_linked?).to be_truthy
        end
      end

      it "when feature reinstate_nonpayment_ivl_enrollment enabled should not reset termination reason on reinstate for shop" do
        members = FactoryBot.build(:hbx_enrollment_member,
                                   applicant_id: shop_family.primary_family_member.id,
                                   hbx_enrollment: shop_enrollment, is_subscriber: true,
                                   coverage_start_on: shop_enrollment.effective_on,
                                   eligibility_date: shop_enrollment.effective_on, tobacco_use: 'Y')
        shop_enrollment.update_attributes(terminate_reason: HbxEnrollment::TermReason::NON_PAYMENT, hbx_enrollment_members: [members])
        EnrollRegistry[:reinstate_nonpayment_ivl_enrollment].feature.stub(:is_enabled).and_return(true)

        shop_enrollment.reinstate
        shop_enrollment.reload
        expect(shop_enrollment.terminate_reason).to eq HbxEnrollment::TermReason::NON_PAYMENT
        reinstated_enrollment = HbxEnrollment.where(family_id: shop_family.id).detect(&:coverage_enrolled?)
        expect(reinstated_enrollment.present?).to be_truthy
        expect(reinstated_enrollment.workflow_state_transitions.where(:to_state => 'coverage_reinstated').present?).to be_truthy
        expect(reinstated_enrollment.effective_on).to eq shop_enrollment.terminated_on.next_day
      end
    end
  end

  context "expired enrollment re-instatement" do
    before do
      EnrollRegistry[:assign_contribution_model_aca_shop].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:admin_ivl_end_date_changes].feature.stub(:is_enabled).and_return(false)
      EnrollRegistry[:admin_ivl_end_date_changes].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:admin_shop_end_date_changes].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:prior_plan_year_shop_sep].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:validate_quadrant].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:indian_alaskan_tribe_details].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:location_residency_verification_type].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:crm_update_family_save].feature.stub(:is_enabled).and_return(false)
    end

    context "for Individual market" do
      let(:person)   { FactoryBot.create(:person, :with_consumer_role, :with_family) }
      let(:ivl_family)        { person.families.first }
      let(:coverage_year) { Date.today.year - 1}

      let!(:hbx_profile) do
        FactoryBot.create(:hbx_profile,
                          :normal_ivl_open_enrollment,
                          coverage_year: coverage_year)
      end

      let(:ivl_enrollment) do
        FactoryBot.create(:hbx_enrollment, :with_health_product,
                          family: ivl_family,
                          household: ivl_family.latest_household,
                          coverage_kind: "health",
                          effective_on: TimeKeeper.date_of_record.beginning_of_year.last_year,
                          enrollment_kind: "open_enrollment",
                          kind: "individual",
                          consumer_role_id: person.consumer_role.id,
                          aasm_state: "coverage_expired")
      end

      it "should re-instate enrollment" do
        ivl_enrollment.reinstate
        reinstated_enrollment = HbxEnrollment.where(family_id: ivl_family.id).detect(&:coverage_selected?)

        expect(reinstated_enrollment.present?).to be_truthy
        expect(reinstated_enrollment.workflow_state_transitions.where(:to_state => 'coverage_reinstated').present?).to be_truthy
        expect(reinstated_enrollment.effective_on).to eq TimeKeeper.date_of_record.beginning_of_year
      end
    end

    context "for SHOP market" do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup expired, and active benefit applications"

      let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile) }
      let(:coverage_kind)     { :health }
      let(:person)          { FactoryBot.create(:person) }
      let(:shop_family)     { FactoryBot.create(:family, :with_primary_family_member, person: person)}
      let(:employee_role)   { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: hired_on, person: person, census_employee: census_employee) }
      let(:hired_on)        { expired_benefit_application.start_on - 10.days }
      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }
      let!(:expired_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: expired_benefit_application.start_on + 1.month,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: expired_benefit_package.id,
                          sponsored_benefit_id: expired_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.active_benefit_group_assignment,
                          product_id: expired_sponsored_benefit.reference_product.id,
                          aasm_state: 'coverage_expired')
      end

      before do
        census_employee.update_attributes(employee_role_id: employee_role.id)
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: expired_benefit_package, census_employee: census_employee, start_on: expired_benefit_package.start_on, end_on: expired_benefit_package.end_on)
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: active_benefit_package, census_employee: census_employee, start_on: active_benefit_package.start_on, end_on: active_benefit_package.end_on)
        census_employee.save
        census_employee.reload
      end

      context 'when re-instated' do
        before do
          expired_enrollment.reinstate
        end

        it "should have re-instate enrollment" do
          reinstated_enrollment = HbxEnrollment.where(family_id: shop_family.id).detect(&:coverage_enrolled?)

          expect(reinstated_enrollment.present?).to be_truthy
          expect(reinstated_enrollment.workflow_state_transitions.where(:to_state => 'coverage_reinstated').present?).to be_truthy
          expect(reinstated_enrollment.effective_on).to eq active_benefit_application.start_on
        end
      end
    end
  end

  context "reinstating prior year terminated enrollment" do
    before do
      EnrollRegistry[:financial_assistance].feature.stub(:is_enabled).and_return(false)
      EnrollRegistry[:assign_contribution_model_aca_shop].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:admin_ivl_end_date_changes].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:admin_shop_end_date_changes].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:prior_plan_year_shop_sep].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:crm_update_family_save].feature.stub(:is_enabled).and_return(false)
      EnrollRegistry[:validate_quadrant].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:indian_alaskan_tribe_details].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:location_residency_verification_type].feature.stub(:is_enabled).and_return(true)
    end
    context "for Individual market" do
      let(:person)   { FactoryBot.create(:person, :with_consumer_role, :with_family) }
      let(:ivl_family)        { person.families.first }
      let(:coverage_year) { Date.today.year - 1}

      let!(:hbx_profile) do
        FactoryBot.create(:hbx_profile,
                          :normal_ivl_open_enrollment,
                          coverage_year: coverage_year)
      end

      let(:ivl_enrollment) do
        FactoryBot.create(:hbx_enrollment, :with_health_product,
                          family: ivl_family,
                          household: ivl_family.latest_household,
                          coverage_kind: "health",
                          effective_on: TimeKeeper.date_of_record.beginning_of_year.last_year,
                          enrollment_kind: "open_enrollment",
                          kind: "individual",
                          aasm_state: "coverage_terminated",
                          consumer_role_id: person.consumer_role.id,
                          terminated_on: (TimeKeeper.date_of_record.beginning_of_year.last_year + 2.months).end_of_month)
      end

      it "should re-instate enrollment and move the reinstated enrollment to expired state" do
        ivl_enrollment.reinstate
        reinstated_enrollment = HbxEnrollment.where(family_id: ivl_family.id).detect(&:coverage_expired?)

        expect(reinstated_enrollment.present?).to be_truthy
        expect(reinstated_enrollment.workflow_state_transitions.where(:to_state => 'coverage_reinstated').present?).to be_truthy
        expect(reinstated_enrollment.effective_on).to eq ivl_enrollment.terminated_on.next_day
      end
    end

    context "for SHOP market" do

      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup terminated and active benefit applications"

      let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile) }
      let(:coverage_kind)     { :health }
      let(:person)          { FactoryBot.create(:person) }
      let(:shop_family)     { FactoryBot.create(:family, :with_primary_family_member, person: person)}
      let(:employee_role)   { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: hired_on, person: person, census_employee: census_employee) }
      let(:hired_on)        { terminated_benefit_application.start_on - 10.days }
      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }
      let!(:terminated_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: terminated_benefit_application.start_on + 1.month,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: terminated_benefit_package.id,
                          sponsored_benefit_id: terminated_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.active_benefit_group_assignment,
                          product_id: terminated_sponsored_benefit.reference_product.id,
                          aasm_state: 'coverage_terminated',
                          terminated_on: terminated_benefit_application.end_on - 2.months)
      end

      before do
        census_employee.update_attributes(employee_role_id: employee_role.id)
        census_employee.benefit_group_assignments <<
          build(:benefit_group_assignment, benefit_group: terminated_benefit_package, census_employee: census_employee, start_on: terminated_benefit_package.start_on, end_on: terminated_benefit_package.end_on)
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: active_benefit_package, census_employee: census_employee, start_on: active_benefit_package.start_on, end_on: active_benefit_package.end_on)
        census_employee.save
        census_employee.reload
      end

      context 'when re-instated' do
        before do
          terminated_enrollment.reinstate
        end

        it "should have re-instate enrollment" do
          reinstated_enrollment = HbxEnrollment.where(family_id: shop_family.id).detect{|e| e.coverage_terminated? && e.id.to_s != terminated_enrollment.id.to_s}
          expect(reinstated_enrollment.present?).to be_truthy
          expect(reinstated_enrollment.workflow_state_transitions.where(:to_state => 'coverage_reinstated').present?).to be_truthy
          expect(reinstated_enrollment.effective_on).to eq terminated_enrollment.terminated_on.next_day
        end
      end
    end
  end

  ###########

  describe "#is_reinstated_enrollment?" do
    let(:hbx_enrollment) { HbxEnrollment.new(kind: 'employer_sponsored') }
    let(:workflow_state_transition) {FactoryBot.build(:workflow_state_transition,:from_state => "coverage_reinstated", :to_state => "coverage_selected")}
    context 'when enrollment has been reinstated' do
      it "should have reinstated enrollmentt" do
        allow(hbx_enrollment).to receive(:workflow_state_transitions).and_return([workflow_state_transition])
        expect(hbx_enrollment.is_reinstated_enrollment?).to be_truthy
      end
    end
    context 'when enrollment has not been reinstated' do
      it "should have reinstated enrollmentt" do
        allow(hbx_enrollment).to receive(:workflow_state_transitions).and_return([])
        expect(hbx_enrollment.is_reinstated_enrollment?).to be_falsey
      end
    end
  end

  describe "#can_be_reinstated?" do

    context "for Individual market" do
      let(:ivl_family)        { FactoryBot.create(:family, :with_primary_family_member) }
      let(:coverage_year) { Date.today.year - 1}
      let!(:hbx_profile) do
        FactoryBot.create(:hbx_profile,
                          :normal_ivl_open_enrollment,
                          coverage_year: coverage_year)
      end

      let(:ivl_enrollment)    do
        FactoryBot.create(:hbx_enrollment,
                          family: ivl_family,
                          household: ivl_family.latest_household,
                          coverage_kind: "health",
                          effective_on: TimeKeeper.date_of_record.last_year.beginning_of_year,
                          enrollment_kind: "open_enrollment",
                          kind: "individual",
                          aasm_state: "coverage_terminated",
                          terminated_on: TimeKeeper.date_of_record.last_year.end_of_year)
      end

      before do
        EnrollRegistry[:financial_assistance].feature.stub(:is_enabled).and_return(false)
        EnrollRegistry[:admin_ivl_end_date_changes].feature.stub(:is_enabled).and_return(true)
        EnrollRegistry[:admin_shop_end_date_changes].feature.stub(:is_enabled).and_return(true)
        EnrollRegistry[:validate_quadrant].feature.stub(:is_enabled).and_return(true)
      end

      it "previous year terminated enrollment  can be reinstated?" do
        expect(ivl_enrollment.can_be_reinstated?).to be_truthy
      end

      it "previous year expired enrollment can be reinstated?" do
        ivl_enrollment.update_attributes(aasm_state: 'coverage_expired', terminated_on: nil)
        expect(ivl_enrollment.can_be_reinstated?).to be_truthy
      end

      it "enrollment terminated couple of years ago cannot be reinstated?" do
        ivl_enrollment.update_attributes(effective_on: TimeKeeper.date_of_record.years_ago(2).beginning_of_year, terminated_on: TimeKeeper.date_of_record.years_ago(2).end_of_year)
        expect(ivl_enrollment.can_be_reinstated?).to be_falsey
      end

      it "enrollment expired couple of years ago cannot be reinstated?" do
        ivl_enrollment.update_attributes(aasm_state: 'coverage_expired', terminated_on: nil, effective_on: TimeKeeper.date_of_record.years_ago(2).beginning_of_year)
        expect(ivl_enrollment.can_be_reinstated?).to be_falsey
      end

      it "enrollment terminated during current year can be reinstated?" do
        ivl_enrollment.update_attributes(effective_on: TimeKeeper.date_of_record.beginning_of_year, terminated_on: TimeKeeper.date_of_record.end_of_month)
        ivl_enrollment.reload
        expect(ivl_enrollment.can_be_reinstated?).to be_truthy
      end

      it "enrollment terminated with non payment reason, when feature disabled" do
        EnrollRegistry[:reinstate_nonpayment_ivl_enrollment].feature.stub(:is_enabled).and_return(false)
        ivl_enrollment.update_attributes(terminate_reason: HbxEnrollment::TermReason::NON_PAYMENT)
        ivl_enrollment.reload
        expect(ivl_enrollment.can_be_reinstated?).to be_falsey
      end

      it "enrollment terminated with non payment reason, when feature enabled" do
        EnrollRegistry[:reinstate_nonpayment_ivl_enrollment].feature.stub(:is_enabled).and_return(true)
        ivl_enrollment.update_attributes(terminate_reason: HbxEnrollment::TermReason::NON_PAYMENT)
        ivl_enrollment.reload
        expect(ivl_enrollment.can_be_reinstated?).to be_truthy
      end
    end

    context "for SHOP market", dbclean: :after_each do

      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"

      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
      let(:effective_on) { current_effective_date }
      let(:hired_on) { TimeKeeper.date_of_record - 3.months }
      let(:employee_created_at) { hired_on }
      let(:employee_updated_at) { employee_created_at }

      let(:person) {FactoryBot.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789')}
      let(:shop_family) {FactoryBot.create(:family, :with_primary_family_member)}
      let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
      let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}

      let(:aasm_state) { :active }
      let(:census_employee) do
        create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package, hired_on: hired_on, created_at: employee_created_at,
                                                          updated_at: employee_updated_at)
      end
      let(:employee_role) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: census_employee.hired_on, census_employee_id: census_employee.id) }
      let(:enrollment_kind) { "open_enrollment" }
      let(:special_enrollment_period_id) { nil }
      let!(:enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          coverage_kind: "health",
                          family: shop_family,
                          effective_on: effective_on,
                          enrollment_kind: enrollment_kind,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: current_benefit_package.id,
                          sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                          employee_role_id: employee_role.id,
                          product: sponsored_benefit.reference_product,
                          benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
      end

      before do
        EnrollRegistry[:financial_assistance].feature.stub(:is_enabled).and_return(false)
        EnrollRegistry[:admin_ivl_end_date_changes].feature.stub(:is_enabled).and_return(true)
        EnrollRegistry[:admin_shop_end_date_changes].feature.stub(:is_enabled).and_return(true)
        EnrollRegistry[:assign_contribution_model_aca_shop].feature.stub(:is_enabled).and_return(true)
        EnrollRegistry[:prior_plan_year_shop_sep].feature.stub(:is_enabled).and_return(true)
        EnrollRegistry[:validate_quadrant].feature.stub(:is_enabled).and_return(true)
      end

      context "reinstating coverage_terminated enrollment" do
        context 'reinstated effective date falls outside active plan year' do
          before do
            enrollment.update_attributes(aasm_state: 'coverage_terminated', terminated_on: current_benefit_package.benefit_application.end_on)
            enrollment.reload
          end

          it "should return false" do
            expect(enrollment.can_be_reinstated?).to be_falsey
          end
        end

        context 'reinstated effective date falls with in range of active plan year' do
          before do
            enrollment.update_attributes(aasm_state: 'coverage_terminated', terminated_on: current_benefit_package.benefit_application.end_on - 1.month)
            enrollment.reload
          end

          it "should return true" do
            expect(enrollment.can_be_reinstated?).to be_truthy
          end
        end

        context 'reinstated effective date falls with in range of terminated prior plan year', dbclean: :after_each do
          before do
            effective_period = current_benefit_package.start_on.last_year..(current_benefit_package.end_on - 1.month).last_year
            current_benefit_package.benefit_application.update_attributes(aasm_state: :terminated, effective_period: effective_period)
            census_employee.benefit_group_assignments.first.update_attributes(start_on: current_benefit_package.benefit_application.start_on, end_on: current_benefit_package.benefit_application.end_on)
            census_employee.update_attributes(hired_on: current_benefit_package.benefit_application.start_on - 3.months)
            enrollment.update_attributes(aasm_state: 'coverage_terminated', terminated_on: current_benefit_package.benefit_application.end_on - 1.month)
            enrollment.reload
          end

          it "should return true" do
            expect(enrollment.can_be_reinstated?).to be_truthy
          end
        end
      end

      context "reinstating coverage_terminated pending enrollment" do
        context 'reinstated effective date falls outside active plan year' do
          before do
            enrollment.update_attributes(aasm_state: 'coverage_termination_pending', terminated_on: current_benefit_package.benefit_application.end_on)
            enrollment.reload
          end

          it "should return false" do
            expect(enrollment.can_be_reinstated?).to be_falsey
          end
        end

        context 'reinstated effective date falls with in range of active plan year' do
          before do
            enrollment.update_attributes(aasm_state: 'coverage_termination_pending', terminated_on: current_benefit_package.benefit_application.end_on - 1.month)
            enrollment.reload
          end

          it "should return true" do
            expect(enrollment.can_be_reinstated?).to be_truthy
          end
        end
      end

      context "reinstating coverage_expired prior year enrollment" do
        context 'reinstated effective date falls inside active plan year' do
          include_context "setup expired, and active benefit applications"

          let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }
          let(:coverage_kind)     { :health }
          let(:enrollment) do
            FactoryBot.create(:hbx_enrollment,
                              household: shop_family.latest_household,
                              family: shop_family,
                              coverage_kind: coverage_kind,
                              effective_on: expired_benefit_application.start_on + 1.month,
                              kind: "employer_sponsored",
                              benefit_sponsorship_id: benefit_sponsorship.id,
                              sponsored_benefit_package_id: expired_benefit_package.id,
                              sponsored_benefit_id: expired_sponsored_benefit.id,
                              employee_role_id: employee_role.id,
                              benefit_group_assignment: census_employee.active_benefit_group_assignment,
                              product_id: expired_sponsored_benefit.reference_product.id,
                              aasm_state: 'coverage_expired')
          end
          before do
            census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: expired_benefit_package, census_employee: census_employee, start_on: expired_benefit_package.start_on, end_on: expired_benefit_package.end_on)
            census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: active_benefit_package, census_employee: census_employee, start_on: active_benefit_package.start_on, end_on: active_benefit_package.end_on)
            census_employee.save
            census_employee
          end

          it "should return true" do
            expect(enrollment.can_be_reinstated?).to be_truthy
          end
        end

        context 'reinstating coverage_expired old plan year enrollment' do
          include_context "setup expired, and active benefit applications"

          let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.years_ago(2) }
          let(:coverage_kind)     { :health }
          let(:enrollment) do
            FactoryBot.create(:hbx_enrollment,
                              household: shop_family.latest_household,
                              family: shop_family,
                              coverage_kind: coverage_kind,
                              effective_on: expired_benefit_application.start_on + 1.month,
                              kind: "employer_sponsored",
                              benefit_sponsorship_id: benefit_sponsorship.id,
                              sponsored_benefit_package_id: expired_benefit_package.id,
                              sponsored_benefit_id: expired_sponsored_benefit.id,
                              employee_role_id: employee_role.id,
                              benefit_group_assignment: census_employee.active_benefit_group_assignment,
                              product_id: expired_sponsored_benefit.reference_product.id,
                              aasm_state: 'coverage_expired')
          end

          before do
            census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: expired_benefit_package, census_employee: census_employee, start_on: expired_benefit_package.start_on, end_on: expired_benefit_package.end_on)
            census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: active_benefit_package, census_employee: census_employee, start_on: active_benefit_package.start_on, end_on: active_benefit_package.end_on)
            census_employee.save
            census_employee
          end

          it "should return true" do
            expect(enrollment.can_be_reinstated?).to be_truthy
          end
        end
      end

      context 'for reinstated enrollment no active coverage offering by employer' do

        before do
          current_benefit_package.benefit_application.update_attributes(aasm_state: :terminated)
          enrollment.update_attributes(aasm_state: 'coverage_terminated', terminated_on: current_benefit_package.benefit_application.end_on - 1.month)
          enrollment.reload
        end

        it "should return true" do
          expect(enrollment.can_be_reinstated?).to be_truthy
        end
      end

      context "reinstating employer sponsored enrollment for cobra employee" do

        before do
          enrollment.update_attributes(aasm_state: 'coverage_terminated', terminated_on: current_benefit_package.benefit_application.end_on - 1.month)
          enrollment.employee_role.census_employee.update_attributes(aasm_state: 'cobra_linked', cobra_begin_date: TimeKeeper.date_of_record)
        end

        it "should return false" do
          expect(enrollment.can_be_reinstated?).to be_falsey
        end
      end

      context "reinstating cobra enrollment for active employee" do

        before do
          enrollment.update_attributes(kind: 'employer_sponsored_cobra', aasm_state: 'coverage_terminated', terminated_on: current_benefit_package.benefit_application.end_on - 1.month)
        end

        it "should return false" do
          expect(enrollment.can_be_reinstated?).to be_falsey
        end

      end
    end
  end

  describe "#term_or_expire_enrollment" do
    let!(:person)          { FactoryBot.create(:person, :with_consumer_role) }
    let!(:family)          { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let!(:hbx_enrollment)  do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.latest_household,
                        coverage_kind: "health",
                        enrollment_kind: "open_enrollment",
                        kind: "individual",
                        aasm_state: "coverage_selected",
                        effective_on: TimeKeeper.date_of_record.beginning_of_month)
    end
    let!(:hbx_profile)       { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period) }

    it 'should terminate an enrollment if term date is passed' do
      hbx_enrollment.term_or_expire_enrollment(TimeKeeper.date_of_record.end_of_month)
      hbx_enrollment.reload
      expect(hbx_enrollment.aasm_state).to eq 'coverage_terminated'
    end
  end

  describe "#has_active_term_or_expired_exists_for_reinstated_date?" do

    before do
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year, 11,1) + 14.days)
      EnrollRegistry[:financial_assistance].feature.stub(:is_enabled).and_return(false)
      EnrollRegistry[:admin_ivl_end_date_changes].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:admin_shop_end_date_changes].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:assign_contribution_model_aca_shop].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:prior_plan_year_shop_sep].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:validate_quadrant].feature.stub(:is_enabled).and_return(true)
    end

    context "for Individual market" do
      let(:ivl_family)        { FactoryBot.create(:family, :with_primary_family_member) }
      let(:coverage_year) { Date.today.year - 1}
      let!(:hbx_profile) do
        FactoryBot.create(:hbx_profile,
                          :normal_ivl_open_enrollment,
                          coverage_year: coverage_year)
      end

      let(:ivl_enrollment)  do
        FactoryBot.create(:hbx_enrollment,
                          family: ivl_family,
                          household: ivl_family.latest_household,
                          coverage_kind: "health",
                          effective_on: TimeKeeper.date_of_record.last_year.beginning_of_month,
                          enrollment_kind: "open_enrollment",
                          kind: "individual",
                          aasm_state: "coverage_terminated",
                          terminated_on: TimeKeeper.date_of_record.end_of_month)
      end

      let(:ivl_enrollment2)  do
        FactoryBot.create(:hbx_enrollment,
                          family: ivl_family,
                          household: ivl_family.latest_household,
                          coverage_kind: "health",
                          enrollment_kind: "open_enrollment",
                          kind: "individual",
                          aasm_state: "coverage_selected",
                          effective_on: TimeKeeper.date_of_record.end_of_month + 1.day)
      end

      it "should return true if active enrollment exists for reinstated date " do
        ivl_enrollment2
        expect(ivl_enrollment.has_active_term_or_expired_exists_for_reinstated_date?).to be_truthy
      end

      it "should return true if termianted enrollment exists for reinstated date" do
        ivl_enrollment2.update_attributes(effective_on: TimeKeeper.date_of_record.end_of_month + 1.day, aasm_state: "coverage_terminated")
        ivl_enrollment2.reload
        expect(ivl_enrollment.has_active_term_or_expired_exists_for_reinstated_date?).to be_truthy
      end

      it "should return true if future active enrollment exists" do
        ivl_enrollment2.update_attributes(aasm_state: "coverage_selected", effective_on: TimeKeeper.date_of_record.beginning_of_month + 1.months)
        ivl_enrollment2.reload
        expect(ivl_enrollment.has_active_term_or_expired_exists_for_reinstated_date?).to be_truthy
      end

      it "should return false if no active enrollment exists for reinstated date" do
        ivl_enrollment2.update_attributes(effective_on: TimeKeeper.date_of_record.end_of_month + 1.day, aasm_state: "coverage_canceled")
        ivl_enrollment2.reload
        expect(ivl_enrollment.has_active_term_or_expired_exists_for_reinstated_date?).to be_falsey
      end

      context 'when prior py feature is enabled', dbclean: :after_each do
        let(:expired_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            family: ivl_family,
                            household: ivl_family.latest_household,
                            coverage_kind: "health",
                            effective_on: TimeKeeper.date_of_record.last_year.beginning_of_month,
                            enrollment_kind: "open_enrollment",
                            kind: "individual",
                            aasm_state: "coverage_expired")
        end

        let(:current_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            family: ivl_family,
                            household: ivl_family.latest_household,
                            coverage_kind: "health",
                            effective_on: TimeKeeper.date_of_record.beginning_of_month,
                            enrollment_kind: "open_enrollment",
                            kind: "individual",
                            aasm_state: "coverage_expired")
        end

        it "should return true if there is an active enrollment exists for reinstated date" do
          current_enrollment
          expect(expired_enrollment.has_active_term_or_expired_exists_for_reinstated_date?).to be_truthy
        end

        it "should return false if there is no enrollment exists for reinstated date" do
          current_enrollment.update_attributes(effective_on: TimeKeeper.date_of_record.beginning_of_month.next_year)
          current_enrollment.reload
          expect(expired_enrollment.has_active_term_or_expired_exists_for_reinstated_date?).to be_falsey
        end
      end

      context 'when prior py feature is disabled', dbclean: :after_each do
        let(:coverage_year) { Date.today.year - 1}
        let!(:hbx_profile) do
          FactoryBot.create(:hbx_profile,
                            :normal_ivl_open_enrollment,
                            coverage_year: coverage_year)
        end

        let(:expired_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            family: ivl_family,
                            household: ivl_family.latest_household,
                            coverage_kind: "health",
                            effective_on: TimeKeeper.date_of_record.last_year.beginning_of_month,
                            enrollment_kind: "open_enrollment",
                            kind: "individual",
                            aasm_state: "coverage_expired")
        end

        let(:current_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            family: ivl_family,
                            household: ivl_family.latest_household,
                            coverage_kind: "health",
                            effective_on: TimeKeeper.date_of_record.beginning_of_month,
                            enrollment_kind: "open_enrollment",
                            kind: "individual",
                            aasm_state: "coverage_expired")
        end

        before do
          EnrollRegistry[:financial_assistance].feature.stub(:is_enabled).and_return(false)
          EnrollRegistry[:admin_ivl_end_date_changes].feature.stub(:is_enabled).and_return(false)
          EnrollRegistry[:admin_shop_end_date_changes].feature.stub(:is_enabled).and_return(false)
          EnrollRegistry[:prior_plan_year_shop_sep].feature.stub(:is_enabled).and_return(false)
          EnrollRegistry[:validate_quadrant].feature.stub(:is_enabled).and_return(true)
        end

        it "should return true if there is an active enrollment exists for reinstated date" do
          current_enrollment
          expect(expired_enrollment.has_active_term_or_expired_exists_for_reinstated_date?).to be_falsey
        end

        it "should return false if there is no enrollment exists for reinstated date" do
          current_enrollment.update_attributes(effective_on: TimeKeeper.date_of_record.beginning_of_month.next_year)
          current_enrollment.reload
          expect(expired_enrollment.has_active_term_or_expired_exists_for_reinstated_date?).to be_falsey
        end
      end
    end

    context "for SHOP market" do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"

      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
      let(:effective_on) { current_effective_date }
      let(:hired_on) { TimeKeeper.date_of_record - 3.months }
      let(:employee_created_at) { hired_on }
      let(:employee_updated_at) { employee_created_at }

      let(:person) {FactoryBot.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789')}
      let(:shop_family) {FactoryBot.create(:family, :with_primary_family_member)}
      let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
      let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}

      let(:aasm_state) { :active }
      let(:census_employee) do
        create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package, hired_on: hired_on, created_at: employee_created_at,
                                                          updated_at: employee_updated_at)
      end
      let(:employee_role) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: census_employee.hired_on, census_employee_id: census_employee.id) }
      let(:enrollment_kind) { "open_enrollment" }
      let(:special_enrollment_period_id) { nil }
      let!(:enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          coverage_kind: "health",
                          family: shop_family,
                          effective_on: effective_on,
                          enrollment_kind: enrollment_kind,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: current_benefit_package.id,
                          sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                          employee_role_id: employee_role.id,
                          product: sponsored_benefit.reference_product,
                          aasm_state: "coverage_terminated",
                          benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
                          terminated_on: effective_on.end_of_month)
      end
      let!(:enrollment2) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          coverage_kind: "health",
                          family: shop_family,
                          effective_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
                          enrollment_kind: enrollment_kind,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: current_benefit_package.id,
                          sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                          employee_role_id: employee_role.id,
                          product: sponsored_benefit.reference_product,
                          aasm_state: "coverage_selected",
                          benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)

      end

      it "should return true if active enrollment exists for reinstated date " do
        expect(enrollment.has_active_term_or_expired_exists_for_reinstated_date?).to be_truthy
      end

      it "should return true if terminated enrollment exists for reinstated date" do
        enrollment2.update_attributes(effective_on: effective_on.end_of_month + 1.day, aasm_state: "coverage_terminated")
        enrollment2.reload
        expect(enrollment.has_active_term_or_expired_exists_for_reinstated_date?).to be_truthy
      end

      it "should return true if future active enrollment exists" do
        enrollment2.update_attributes(effective_on: TimeKeeper.date_of_record.next_month.beginning_of_month + 1.month)
        enrollment2.reload
        expect(enrollment.has_active_term_or_expired_exists_for_reinstated_date?).to be_truthy
      end

      it "should return false if no active enrollment exists for reinstated date" do
        enrollment2.update_attributes(effective_on: effective_on.end_of_month + 1.day, aasm_state: "coverage_canceled")
        enrollment2.reload
        expect(enrollment.has_active_term_or_expired_exists_for_reinstated_date?).to be_falsey
      end

      context "with employer_sponsored & active cobra enrollment" do

        it "should return true if active enrollment exists for reinstated date " do
          enrollment2.update_attributes(kind: "employer_sponsored_cobra")
          enrollment2.reload
          expect(enrollment.has_active_term_or_expired_exists_for_reinstated_date?).to be_truthy
        end

        it "should return true if future active enrollment exists" do
          enrollment2.update_attributes(kind: "employer_sponsored_cobra", effective_on: effective_on.end_of_month + 1.day)
          enrollment2.reload
          expect(enrollment.has_active_term_or_expired_exists_for_reinstated_date?).to be_truthy
        end

        it "should return false if no active enrollment exists for reinstated date" do
          enrollment2.update_attributes(kind: "employer_sponsored_cobra", effective_on: effective_on.end_of_month + 1.day, aasm_state: "coverage_canceled")
          enrollment2.reload
          expect(enrollment.has_active_term_or_expired_exists_for_reinstated_date?).to be_falsey
        end
      end

      context "enrollment from two mutiple employers." do

        include_context "setup benefit market with market catalogs and product packages"
        include_context "setup initial benefit application"

        let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
        let(:effective_on) { current_effective_date }
        let(:hired_on) { TimeKeeper.date_of_record - 3.months }
        let(:employee_created_at) { hired_on }
        let(:employee_updated_at) { employee_created_at }

        let!(:sponsored_benefit2) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
        let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}

        let(:aasm_state) { :active }
        let(:census_employee2) do
          create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package, hired_on: hired_on, created_at: employee_created_at,
                                                            updated_at: employee_updated_at)
        end
        let(:employee_role2) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: census_employee2.hired_on, census_employee_id: census_employee2.id) }
        let(:enrollment_kind) { "open_enrollment" }
        let(:special_enrollment_period_id) { nil }

        let!(:enrollment3) do
          FactoryBot.create(:hbx_enrollment,
                            household: shop_family.latest_household,
                            coverage_kind: "health",
                            family: shop_family,
                            effective_on: effective_on.end_of_month,
                            enrollment_kind: enrollment_kind,
                            kind: "employer_sponsored",
                            benefit_sponsorship_id: benefit_sponsorship.id,
                            sponsored_benefit_package_id: current_benefit_package.id,
                            sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                            employee_role_id: employee_role2.id,
                            product: sponsored_benefit2.reference_product,
                            aasm_state: "coverage_selected",
                            benefit_group_assignment_id: census_employee2.active_benefit_group_assignment.id,
                            terminated_on: effective_on.end_of_month)
        end


        it "should return false when reinstated date enrollment exits with different employer " do
          expect(enrollment3.has_active_term_or_expired_exists_for_reinstated_date?).to be_falsey
        end
      end
    end

    context 'SHOP market for expired enrollment' do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup expired, and active benefit applications"

      let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile) }
      let(:coverage_kind)     { :health }
      let(:person)          { FactoryBot.create(:person) }
      let(:shop_family)     { FactoryBot.create(:family, :with_primary_family_member, person: person)}
      let(:employee_role)   { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: hired_on, person: person, census_employee: census_employee) }
      let(:hired_on)        { expired_benefit_application.start_on - 10.days }
      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }
      let!(:expired_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: expired_benefit_application.start_on + 1.month,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: expired_benefit_package.id,
                          sponsored_benefit_id: expired_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.active_benefit_group_assignment,
                          product_id: expired_sponsored_benefit.reference_product.id,
                          aasm_state: 'coverage_expired')
      end

      let!(:active_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          household: shop_family.latest_household,
                          family: shop_family,
                          coverage_kind: coverage_kind,
                          effective_on: active_benefit_application.start_on + 1.month,
                          kind: "employer_sponsored",
                          benefit_sponsorship_id: benefit_sponsorship.id,
                          sponsored_benefit_package_id: active_benefit_package.id,
                          sponsored_benefit_id: active_sponsored_benefit.id,
                          employee_role_id: employee_role.id,
                          benefit_group_assignment: census_employee.active_benefit_group_assignment,
                          product_id: active_sponsored_benefit.reference_product.id,
                          aasm_state: 'coverage_selected')
      end

      before do
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: expired_benefit_package, census_employee: census_employee, start_on: expired_benefit_package.start_on, end_on: expired_benefit_package.end_on)
        census_employee.benefit_group_assignments << build(:benefit_group_assignment, benefit_group: active_benefit_package, census_employee: census_employee, start_on: active_benefit_package.start_on, end_on: active_benefit_package.end_on)
        census_employee.save
        census_employee
      end

      it "should return true when enrollment exists for reinstated date" do
        expect(expired_enrollment.has_active_term_or_expired_exists_for_reinstated_date?).to be_truthy
      end
    end
  end

  context '.display_make_changes_for_ivl?' do
    let(:user) { FactoryBot.create(:user, roles: ["hbx_staff"]) }
    let!(:person) { FactoryBot.create(:person)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let!(:household) { FactoryBot.create(:household, family: family) }
    let(:hbx_profile) {FactoryBot.create(:hbx_profile)}
    let(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
    let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }
    let(:sep) {SpecialEnrollmentPeriod.new(effective_on: TimeKeeper.date_of_record, start_on: TimeKeeper.date_of_record, end_on: TimeKeeper.date_of_record + 1)}
    let!(:enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: "health",
                        effective_on: TimeKeeper.date_of_record.beginning_of_year,
                        aasm_state: 'coverage_selected')
    end

    before :each do
      allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
      allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
      allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
    end

    context 'for shop' do

      before do
        enrollment.kind = 'employer_sponsored'
        enrollment.save
      end

      it 'should return true' do
        expect(enrollment.display_make_changes_for_ivl?).to be_truthy
      end
    end

    context 'for ivl' do

      before do
        enrollment.kind = 'individual'
        enrollment.save
      end

      context 'family with active sep' do
        before do
          allow(family).to receive(:latest_ivl_sep).and_return sep
        end

        it 'should return true' do
          expect(enrollment.display_make_changes_for_ivl?).to be_truthy
        end
      end

      context 'under open enrollment period' do

        before do
          allow(family).to receive(:is_under_ivl_open_enrollment?).and_return true
        end

        it 'should return true' do
          expect(enrollment.display_make_changes_for_ivl?).to be_truthy
        end
      end
    end
  end


  describe "#reterm_enrollment_with_earlier_date" do
    let(:user) { FactoryBot.create(:user, roles: ["hbx_staff"]) }
    let!(:person) { FactoryBot.create(:person)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let!(:household) { FactoryBot.create(:household, family: family) }
    let(:original_termination_date) { TimeKeeper.date_of_record.next_month.end_of_month }
    let!(:enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: "health",
                        kind: 'employer_sponsored',
                        effective_on: TimeKeeper.date_of_record.last_month.beginning_of_month,
                        terminated_on: original_termination_date,
                        aasm_state: 'coverage_termination_pending')
    end
    let!(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }

    context "shop enrollment" do
      context "enrollment that already terminated with past date" do
        context "with new past or current termination date" do
          let(:terminated_date) { original_termination_date - 1.day }
          let(:original_termination_date) { TimeKeeper.date_of_record.beginning_of_month }

          it "should update enrollment with new end date and notify enrollment" do
            expect(enrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated",
                                                        {:reply_to => glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
                                                         "is_trading_partner_publishable" => false})
            enrollment.reterm_enrollment_with_earlier_date(terminated_date, false)
            enrollment.reload
            expect(enrollment.aasm_state).to eq "coverage_terminated"
            expect(enrollment.terminated_on).to eq terminated_date
          end
        end

        context "new term date greater than current termination date" do
          it "return false" do
            expect(enrollment.reterm_enrollment_with_earlier_date(TimeKeeper.date_of_record + 2.months, false)).to eq false
          end
        end
      end

      context "enrollment that already terminated with future date" do
        context "with new future termination date" do
          it "should update enrollment with new end date and notify enrollment" do
            expect(enrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated",
                                                        {:reply_to => glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
                                                         "is_trading_partner_publishable" => false})
            enrollment.reterm_enrollment_with_earlier_date(TimeKeeper.date_of_record + 1.day, false)
            enrollment.reload
            expect(enrollment.aasm_state).to eq "coverage_termination_pending"
            expect(enrollment.terminated_on).to eq TimeKeeper.date_of_record + 1.day
          end
        end
      end
    end

    context "IVL enrollment" do
      let!(:hbx_profile) { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period, coverage_year: TimeKeeper.date_of_record.year) }

      before do
        enrollment.kind = "individual"
        enrollment.save
      end

      context "enrollment that already terminated with past date" do
        context "with new past or current termination date" do
          it "should update enrollment with new end date and notify enrollment" do
            expect(enrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated",
                                                        {:reply_to => glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
                                                         "is_trading_partner_publishable" => false})
            enrollment.reterm_enrollment_with_earlier_date(TimeKeeper.date_of_record, false)
            enrollment.reload
            expect(enrollment.aasm_state).to eq "coverage_terminated"
            expect(enrollment.terminated_on).to eq TimeKeeper.date_of_record
          end
        end
      end

      context "enrollment that already terminated with future date" do
        context "with new future termination date" do
          it "should update enrollment with new end date and notify enrollment" do
            expect(enrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated",
                                                        {:reply_to => glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
                                                         "is_trading_partner_publishable" => false})
            enrollment.reterm_enrollment_with_earlier_date(TimeKeeper.date_of_record + 1.day, false)
            enrollment.reload
            expect(enrollment.aasm_state).to eq "coverage_terminated"
            expect(enrollment.terminated_on).to eq TimeKeeper.date_of_record + 1.day
          end
        end
      end
    end
  end

  describe '#cancel_terminated_enrollment' do
    let(:user) { FactoryBot.create(:user, roles: ['hbx_staff']) }
    let!(:person) { FactoryBot.create(:person)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let!(:household) { FactoryBot.create(:household, family: family) }
    let!(:enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: 'health',
                        kind: 'employer_sponsored',
                        effective_on: TimeKeeper.date_of_record.last_month.beginning_of_month,
                        terminated_on: TimeKeeper.date_of_record.end_of_month,
                        aasm_state: 'coverage_termination_pending')
    end
    let!(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }

    context 'shop enrollment' do
      context 'enrollment that already terminated with past date' do
        context 'with new termination date == enrollment effective date' do

          before do
            enrollment.update_attributes(aasm_state: 'coverage_terminated', terminated_on: TimeKeeper.date_of_record - 1.day)
            enrollment.reload
          end
          it 'should cancel enrollment' do
            expect(enrollment).to receive(:notify).with('acapi.info.events.hbx_enrollment.terminated',
                                                        {:reply_to => glue_event_queue_name, 'hbx_enrollment_id' => enrollment.hbx_id, 'enrollment_action_uri' => 'urn:openhbx:terms:v1:enrollment#terminate_enrollment',
                                                         'is_trading_partner_publishable' => false})
            enrollment.cancel_terminated_enrollment(TimeKeeper.date_of_record.last_month.beginning_of_month, false)
            enrollment.reload
            expect(enrollment.aasm_state).to eq 'coverage_canceled'
            expect(enrollment.terminated_on).to eq nil
            expect(enrollment.termination_submitted_on).to eq nil
            expect(enrollment.terminate_reason).to eq nil
          end
        end
      end

      context 'enrollment that already terminated with future date' do
        context 'with new termination date == enrollment effective date' do
          it 'should cancel enrollment' do
            expect(enrollment).to receive(:notify).with('acapi.info.events.hbx_enrollment.terminated',
                                                        {:reply_to => glue_event_queue_name, 'hbx_enrollment_id' => enrollment.hbx_id, 'enrollment_action_uri' => 'urn:openhbx:terms:v1:enrollment#terminate_enrollment',
                                                         'is_trading_partner_publishable' => false})
            enrollment.cancel_terminated_enrollment(TimeKeeper.date_of_record.last_month.beginning_of_month, false)
            enrollment.reload
            expect(enrollment.aasm_state).to eq 'coverage_canceled'
            expect(enrollment.terminated_on).to eq nil
            expect(enrollment.termination_submitted_on).to eq nil
            expect(enrollment.terminate_reason).to eq nil
          end
        end
      end
    end

    context 'IVL enrollment' do

      before do
        enrollment.kind = 'individual'
        enrollment.aasm_state = 'coverage_terminated'
        enrollment.save
      end

      context 'enrollment that already terminated with past date' do
        context 'with new termination date == enrollment effective date' do
          it 'should cancel enrollment' do
            enrollment.update_attributes(terminated_on: TimeKeeper.date_of_record - 1.day)
            expect(enrollment).to receive(:notify).with('acapi.info.events.hbx_enrollment.terminated',
                                                        {:reply_to => glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, 'enrollment_action_uri' => 'urn:openhbx:terms:v1:enrollment#terminate_enrollment',
                                                         'is_trading_partner_publishable' => false})
            enrollment.cancel_terminated_enrollment(TimeKeeper.date_of_record.last_month.beginning_of_month, false)
            enrollment.reload
            expect(enrollment.aasm_state).to eq 'coverage_canceled'
            expect(enrollment.terminated_on).to eq nil
            expect(enrollment.termination_submitted_on).to eq nil
            expect(enrollment.terminate_reason).to eq nil
          end
        end
      end

      context 'enrollment that already terminated with future date' do
        context 'with new termination date == enrollment effective date' do
          it 'should cancel enrollment' do
            expect(enrollment).to receive(:notify).with('acapi.info.events.hbx_enrollment.terminated',
                                                        {:reply_to => glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
                                                         "is_trading_partner_publishable" => false})
            enrollment.cancel_terminated_enrollment(TimeKeeper.date_of_record.last_month.beginning_of_month, false)
            enrollment.reload
            expect(enrollment.aasm_state).to eq 'coverage_canceled'
            expect(enrollment.terminated_on).to eq nil
            expect(enrollment.termination_submitted_on).to eq nil
            expect(enrollment.terminate_reason).to eq nil
          end
        end
      end
    end
  end
end
