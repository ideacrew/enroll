# frozen_string_literal: true

require 'rails_helper'
require 'aasm/rspec'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require File.join(Rails.root, 'spec/shared_contexts/dchbx_product_selection')

describe "#cancel_coverage event for shop", dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile) }
  let(:coverage_kind)     { :health }
  let(:person)          { FactoryBot.create(:person) }
  let(:shop_family)     { FactoryBot.build_stubbed(:family, :with_primary_family_member, person: person)}
  let(:employee_role)   { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: hired_on, person: person, census_employee: census_employee) }
  let(:hired_on)        { expired_benefit_application.start_on - 10.days }

  context 'when employee has existing expired coverage in expired py' do
    include_context "setup expired, and active benefit applications"

    before do
      EnrollRegistry[:prior_plan_year_shop_sep].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:validate_quadrant].feature.stub(:is_enabled).and_return(true)
    end

    let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }
    let!(:enrollment) do
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

    it 'should cancel the expired enrollment' do
      enrollment.cancel_coverage!
      expect(enrollment.aasm_state).to eq "coverage_canceled"
    end
  end

  context 'when employee has existing expired coverage in expired py' do
    include_context "setup terminated and active benefit applications"

    before do
      EnrollRegistry[:prior_plan_year_shop_sep].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:validate_quadrant].feature.stub(:is_enabled).and_return(true)
    end

    let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }
    let!(:enrollment) do
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
                        aasm_state: 'coverage_terminated')
    end

    it 'should cancel the terminated enrollment' do
      enrollment.cancel_coverage!
      expect(enrollment.aasm_state).to eq "coverage_canceled"
    end
  end
end

describe "#select_coverage event for shop", dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile) }
  let(:coverage_kind)     { :health }
  let(:person)          { FactoryBot.create(:person) }
  let(:shop_family)     { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:employee_role)   { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: hired_on, person: person, census_employee: census_employee) }
  let(:hired_on)        { expired_benefit_application.start_on - 10.days }

  context 'when employee has existing expired coverage and active coverage and purchased new enrollment in expired py using sep' do
    include_context "setup expired, and active benefit applications"

    let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }
    let(:qle_kind) {FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date)}
    let(:sep) do
      sep = shop_family.special_enrollment_periods.new
      sep.effective_on_kind = 'date_of_event'
      sep.qualifying_life_event_kind = qle_kind
      sep.qle_on = expired_benefit_application.start_on + 1.month
      sep.start_on = sep.qle_on
      sep.end_on = TimeKeeper.date_of_record + 30.days
      sep.coverage_renewal_flag = true
      sep.save
      sep
    end
    let!(:active_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        household: shop_family.latest_household,
                        family: shop_family,
                        coverage_kind: coverage_kind,
                        effective_on: active_benefit_application.start_on,
                        kind: "employer_sponsored",
                        benefit_sponsorship_id: benefit_sponsorship.id,
                        sponsored_benefit_package_id: active_benefit_package.id,
                        sponsored_benefit_id: active_sponsored_benefit.id,
                        employee_role_id: employee_role.id,
                        benefit_group_assignment: census_employee.active_benefit_group_assignment,
                        product_id: active_sponsored_benefit.reference_product.id,
                        aasm_state: 'coverage_enrolled')
    end

    let!(:expired_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        household: shop_family.latest_household,
                        family: shop_family,
                        coverage_kind: coverage_kind,
                        effective_on: expired_benefit_application.start_on + 1.month,
                        kind: "employer_sponsored",
                        benefit_sponsorship_id: benefit_sponsorship.id,
                        benefit_group_assignment_id: expired_bga.id,
                        sponsored_benefit_package_id: expired_benefit_package.id,
                        sponsored_benefit_id: expired_sponsored_benefit.id,
                        employee_role_id: employee_role.id,
                        product_id: expired_sponsored_benefit.reference_product.id,
                        aasm_state: 'coverage_expired')
    end

    let!(:shopping_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        household: shop_family.latest_household,
                        family: shop_family,
                        coverage_kind: coverage_kind,
                        effective_on: expired_benefit_application.start_on + 1.month,
                        special_enrollment_period_id: sep.id,
                        benefit_group_assignment_id: expired_bga.id,
                        predecessor_enrollment_id: expired_enrollment.id,
                        kind: "employer_sponsored",
                        benefit_sponsorship_id: benefit_sponsorship.id,
                        sponsored_benefit_package_id: expired_benefit_package.id,
                        sponsored_benefit_id: expired_sponsored_benefit.id,
                        employee_role_id: employee_role.id,
                        product_id: expired_sponsored_benefit.reference_product.id,
                        aasm_state: 'shopping')
    end

    let(:expired_bga) do
      build(:benefit_group_assignment, benefit_group: expired_benefit_package, census_employee: census_employee, start_on: expired_benefit_package.start_on, end_on: expired_benefit_package.end_on)
    end

    let(:active_bga) do
      build(:benefit_group_assignment, benefit_group: active_benefit_package, census_employee: census_employee, start_on: active_benefit_package.start_on, end_on: active_benefit_package.end_on)
    end

    before do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:financial_assistance).and_return(false)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:prior_plan_year_ivl_sep).and_return(true)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:prior_plan_year_shop_sep).and_return(true)
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_quadrant).and_return true
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:display_county).and_return false
      census_employee.benefit_group_assignments << expired_bga
      census_employee.benefit_group_assignments << active_bga
      census_employee.save
      census_employee
    end

    it 'should cancel the expired enrollment and generate a new enrollment in expired state' do
      shopping_enrollment.select_coverage!
      shopping_enrollment.family.reload
      family = shopping_enrollment.family
      expect(family.hbx_enrollments.count).to eq 4
      expect(family.hbx_enrollments.map(&:aasm_state)).to match_array(["coverage_canceled", "coverage_canceled", "coverage_expired", "coverage_enrolled"])
    end
  end

  context 'when employee has existing terminated coverage and active coverage and purchased new enrollment in terminated py using sep' do
    include_context "setup terminated and active benefit applications"

    let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_year.prev_year }
    let(:qle_kind) {FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date)}
    let(:sep) do
      sep = shop_family.special_enrollment_periods.new
      sep.effective_on_kind = 'date_of_event'
      sep.qualifying_life_event_kind = qle_kind
      sep.qle_on = terminated_benefit_application.start_on + 1.month
      sep.start_on = sep.qle_on
      sep.end_on = TimeKeeper.date_of_record + 30.days
      sep.coverage_renewal_flag = true
      sep.save
      sep
    end
    let!(:active_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        household: shop_family.latest_household,
                        family: shop_family,
                        coverage_kind: coverage_kind,
                        effective_on: active_benefit_application.start_on,
                        kind: "employer_sponsored",
                        benefit_sponsorship_id: benefit_sponsorship.id,
                        sponsored_benefit_package_id: active_benefit_package.id,
                        sponsored_benefit_id: active_sponsored_benefit.id,
                        employee_role_id: employee_role.id,
                        benefit_group_assignment: census_employee.active_benefit_group_assignment,
                        product_id: active_sponsored_benefit.reference_product.id,
                        aasm_state: 'coverage_enrolled')
    end

    let!(:terminated_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        household: shop_family.latest_household,
                        family: shop_family,
                        coverage_kind: coverage_kind,
                        effective_on: terminated_benefit_package.start_on,
                        special_enrollment_period_id: sep.id,
                        kind: "employer_sponsored",
                        benefit_sponsorship_id: benefit_sponsorship.id,
                        sponsored_benefit_package_id: terminated_benefit_package.id,
                        sponsored_benefit_id: terminated_sponsored_benefit.id,
                        employee_role_id: employee_role.id,
                        benefit_group_assignment: terminated_bga,
                        product_id: terminated_sponsored_benefit.reference_product.id,
                        aasm_state: 'coverage_terminated')
    end

    let!(:shopping_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        household: shop_family.latest_household,
                        family: shop_family,
                        coverage_kind: coverage_kind,
                        effective_on: terminated_benefit_package.start_on + 2.months,
                        special_enrollment_period_id: sep.id,
                        predecessor_enrollment_id: terminated_enrollment.id,
                        kind: "employer_sponsored",
                        benefit_sponsorship_id: benefit_sponsorship.id,
                        sponsored_benefit_package_id: terminated_benefit_package.id,
                        sponsored_benefit_id: terminated_sponsored_benefit.id,
                        employee_role_id: employee_role.id,
                        benefit_group_assignment: terminated_bga,
                        product_id: terminated_sponsored_benefit.reference_product.id,
                        aasm_state: 'shopping')
    end


    let(:active_bga) do
      build(:benefit_group_assignment, benefit_group: active_benefit_package, census_employee: census_employee, start_on: active_benefit_package.start_on, end_on: active_benefit_package.end_on)
    end

    let(:terminated_bga) do
      build(:benefit_group_assignment, benefit_group: terminated_benefit_package, census_employee: census_employee, start_on: terminated_benefit_application.start_on,  end_on: terminated_benefit_application.end_on)
    end

    before do
      EnrollRegistry[:financial_assistance].feature.stub(:is_enabled).and_return(false)
      EnrollRegistry[:prior_plan_year_ivl_sep].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:prior_plan_year_shop_sep].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:validate_quadrant].feature.stub(:is_enabled).and_return(true)
      census_employee.benefit_group_assignments << terminated_bga
      census_employee.benefit_group_assignments << active_bga
      census_employee.save
      census_employee
    end

    it 'should cancel the expired enrollment and generate a new enrollment in expired state' do
      shopping_enrollment.select_coverage!
      shopping_enrollment.family.reload
      family = shopping_enrollment.family
      expect(family.hbx_enrollments.count).to eq 3
      expect(family.hbx_enrollments.map(&:aasm_state)).to match_array(["coverage_enrolled", "coverage_terminated", "coverage_terminated"])
    end
  end
end

describe ".parent enrollments", dbclean: :around_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month - 1.month }
  let(:effective_on) { current_effective_date }
  let(:hired_on) { TimeKeeper.date_of_record - 3.months }
  let(:employee_created_at) { hired_on }
  let(:employee_updated_at) { employee_created_at }
  let(:shop_family) {FactoryBot.create(:family, :with_primary_family_member)}
  let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
  let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}

  let(:aasm_state) { :active }
  let(:census_employee) do
    FactoryBot.create(:census_employee, :with_active_assignment,
                      benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile,
                      benefit_group: current_benefit_package, hired_on: hired_on, created_at: employee_created_at,
                      updated_at: employee_updated_at)
  end

  let(:employee_role) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: census_employee.hired_on, census_employee_id: census_employee.id) }
  let(:enrollment_kind) { "open_enrollment" }
  let(:special_enrollment_period_id) { nil }

  let!(:active_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      household: shop_family.latest_household,
                      coverage_kind: "health",
                      family: shop_family,
                      effective_on: effective_on + 1.month,
                      enrollment_kind: enrollment_kind,
                      kind: "employer_sponsored",
                      benefit_sponsorship_id: benefit_sponsorship.id,
                      sponsored_benefit_package_id: current_benefit_package.id,
                      sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                      employee_role_id: employee_role.id,
                      product: sponsored_benefit.reference_product,
                      aasm_state: "coverage_selected",
                      predecessor_enrollment_id: terminated_enrollment.id,
                      benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
  end


  let!(:terminated_enrollment) do
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


  context "enrollment with predecessor_enrollment_id field exists", dbclean: :around_each do
    it "should return previous contionus enrollemnt " do
      expect(active_enrollment.parent_enrollment).to eq terminated_enrollment
      expect(active_enrollment.effective_on).to eq terminated_enrollment.terminated_on + 1.day
      expect(terminated_enrollment.terminated_on).to eq active_enrollment.effective_on - 1.day
    end
  end

  context "contionus enrollments before predecessor_enrollment_id field introduced", dbclean: :around_each do

    before do
      active_enrollment.effective_on = HbxEnrollment::PREDECESSOR_ID_INTRODUCTION_DATE
      active_enrollment.created_at = HbxEnrollment::PREDECESSOR_ID_INTRODUCTION_DATE
      active_enrollment.save

      terminated_enrollment.effective_on = HbxEnrollment::PREDECESSOR_ID_INTRODUCTION_DATE - 1.month
      terminated_enrollment.created_at = HbxEnrollment::PREDECESSOR_ID_INTRODUCTION_DATE - 1.month
      terminated_enrollment.terminated_on = HbxEnrollment::PREDECESSOR_ID_INTRODUCTION_DATE - 1.day
      terminated_enrollment.save
    end

    it "should match & return previous contionus enrollment" do
      expect(active_enrollment.parent_enrollment).to eq terminated_enrollment
      expect(active_enrollment.effective_on).to eq HbxEnrollment::PREDECESSOR_ID_INTRODUCTION_DATE
      expect(terminated_enrollment.terminated_on).to eq HbxEnrollment::PREDECESSOR_ID_INTRODUCTION_DATE - 1.day
    end
  end

  context 'can_renew_coverage?' do
    let!(:person11)          { FactoryBot.create(:person, :with_consumer_role) }
    let!(:family11)          { FactoryBot.create(:family, :with_primary_family_member, person: person11) }
    let!(:hbx_enrollment11)  { FactoryBot.create(:hbx_enrollment, household: family11.active_household, family: family11) }
    let!(:hbx_profile)       { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period) }
    let!(:renewal_bcp)       { HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period }

    context 'shop enrollment' do
      it 'should return false' do
        expect(hbx_enrollment11.can_renew_coverage?(renewal_bcp.start_on)).to be_falsey
      end
    end

    context 'ivl enrollment' do
      before do
        hbx_enrollment11.update_attributes!(kind: 'individual')
      end

      it 'should return true' do
        expect(hbx_enrollment11.can_renew_coverage?(renewal_bcp.start_on)).to be_truthy
      end
    end
  end

  context 'cancel_ivl_enrollment' do
    let!(:person12)         { FactoryBot.create(:person, :with_consumer_role) }
    let!(:family12)         { FactoryBot.create(:family, :with_primary_family_member, person: person12) }
    let!(:hbx_enrollment12) { FactoryBot.create(:hbx_enrollment, household: family12.active_household, family: family12) }

    context 'shop enrollment' do
      before do
        hbx_enrollment12.cancel_ivl_enrollment
      end

      it 'should not cancel the enrollment' do
        expect(hbx_enrollment12.aasm_state).not_to eq('coverage_canceled')
      end
    end

    context 'ivl health enrollment' do
      before do
        hbx_enrollment12.update_attributes!(kind: 'individual')
        hbx_enrollment12.cancel_ivl_enrollment
      end

      it 'should cancel the enrollment' do
        expect(hbx_enrollment12.aasm_state).to eq('coverage_canceled')
      end

      it 'should create the workflow_state_transition object' do
        expect(hbx_enrollment12.workflow_state_transitions.count).to eq(1)
      end
    end

    context 'ivl dental enrollment' do
      before do
        hbx_enrollment12.update_attributes!(kind: 'individual', coverage_kind: 'dental')
        hbx_enrollment12.cancel_ivl_enrollment
      end

      it 'should cancel the enrollment' do
        expect(hbx_enrollment12.aasm_state).to eq('coverage_canceled')
      end

      it 'should create the workflow_state_transition object' do
        expect(hbx_enrollment12.workflow_state_transitions.count).to eq(1)
      end

      it 'should return latest_wfst' do
        expect(hbx_enrollment12.latest_wfst).to be_a(::WorkflowStateTransition)
      end
    end
  end

  context 'is_waived?' do
    context 'non-waived enrollment' do
      it 'should return false if the enrollment is non-waived' do
        expect(active_enrollment.is_waived?).to be_falsy
      end
    end

    context 'waived enrollment' do
      before {active_enrollment.update_attributes!(aasm_state: 'shopping')}
      context 'with event waive_coverage!' do
        before {active_enrollment.waive_coverage!}

        it 'should return true if the enrollment is waived' do
          expect(active_enrollment.is_waived?).to be_truthy
        end
      end

      context 'with event waive_coverage' do
        before {active_enrollment.waive_coverage}

        it 'should return true if the enrollment is waived' do
          expect(active_enrollment.is_waived?).to be_truthy
        end
      end
    end
  end
end

describe 'calculate effective_on' do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:service) {BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(initial_application)}
  let(:start_on) {TimeKeeper.date_of_record.next_month.beginning_of_month}
  let(:open_enrollment_start_on) {TimeKeeper.date_of_record.beginning_of_month}
  let!(:off_cycle_application) do
    application = FactoryBot.create(
      :benefit_sponsors_benefit_application,
      :with_benefit_sponsor_catalog,
      :with_benefit_package,
      benefit_sponsorship: benefit_sponsorship,
      fte_count: 8,
      aasm_state: "enrollment_open",
      effective_period: start_on..start_on.next_year.prev_day,
      open_enrollment_period: open_enrollment_start_on..(open_enrollment_start_on + 9.days)
    )
    application.benefit_sponsor_catalog.save!
    application
  end
  let(:person)       { FactoryBot.create(:person, :with_family) }
  let(:family)       { person.primary_family }
  let(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package, hired_on: start_on.prev_day) }
  let(:employee_role) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, person: person, census_employee_id: census_employee.id) }
  let(:calculated_effective_on) do
    HbxEnrollment.calculate_effective_on_from(
      market_kind: 'shop',
      qle: false,
      family: family,
      employee_role: employee_role,
      benefit_group: nil,
      benefit_sponsorship: HbxProfile.current_hbx.try(:benefit_sponsorship)
    )
  end

  before do
    service.schedule_termination(TimeKeeper.date_of_record.end_of_month, TimeKeeper.date_of_record, "voluntary", "test", false)
  end

  it 'effective date on CCHH page should return off_cycle_application effective date' do
    expect(calculated_effective_on).to eq off_cycle_application.effective_period.min
  end
end

describe '.cancel_or_termed_by_benefit_package', dbclean: :around_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month - 6.months }
  let(:aasm_state) { :active }
  let(:benefit_package) { initial_application.benefit_packages[0] }
  let(:person) { FactoryBot.create(:person, :with_employee_role, :with_family) }
  let(:family) { person.primary_family }
  let!(:census_employee) do
    ce = FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package)
    ce.update_attributes!(employee_role_id: person.employee_roles.first.id)
    person.employee_roles.first.update_attributes(census_employee_id: ce.id)
    ce
  end
  let!(:enrollment) do
    FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                      household: family.latest_household,
                      coverage_kind: 'health',
                      family: family,
                      effective_on: benefit_package.start_on,
                      kind: 'employer_sponsored',
                      benefit_sponsorship_id: benefit_sponsorship.id,
                      sponsored_benefit_package_id: current_benefit_package.id,
                      employee_role_id: census_employee.employee_role.id,
                      sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                      product: current_benefit_package.sponsored_benefits[0].reference_product,
                      benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
  end

  context 'enrollment terminated for benefit package' do
    before do
      enrollment.terminate_coverage!(benefit_package.end_on)
    end

    it "should return terminated enrollment" do
      enrollment_scope = HbxEnrollment.cancel_or_termed_by_benefit_package(benefit_package)
      expect(enrollment_scope.count).to eq 1
      expect(enrollment_scope.first).to eq enrollment
      expect(enrollment_scope.first.terminated_on).to eq benefit_package.end_on
    end
  end

  context 'future terminated enrollment for benefit package' do
    before do
      enrollment.schedule_coverage_termination!(benefit_package.end_on)
    end

    it "should return future terminated enrollment" do
      enrollment_scope = HbxEnrollment.cancel_or_termed_by_benefit_package(benefit_package)
      expect(enrollment_scope.count).to eq 1
      expect(enrollment_scope.first).to eq enrollment
      expect(enrollment_scope.first.terminated_on).to eq benefit_package.end_on
    end
  end

  context 'canceled enrollment for benefit package' do
    before do
      initial_application.cancel!
      enrollment.cancel_coverage!
    end

    it "should return terminated enrollment" do
      enrollment_scope = HbxEnrollment.cancel_or_termed_by_benefit_package(benefit_package)
      expect(enrollment_scope.count).to eq 1
      expect(enrollment_scope.first).to eq enrollment
      expect(enrollment_scope.first.terminated_on).to eq nil
    end
  end
end

describe '.update_reinstate_coverage', dbclean: :around_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:current_effective_date) {TimeKeeper.date_of_record.beginning_of_month - 6.month}
  let(:person) { FactoryBot.create(:person, :with_employee_role, :with_family) }
  let(:family) { person.primary_family }
  let!(:census_employee) do
    ce = FactoryBot.create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package)
    ce.update_attributes!(employee_role_id: person.employee_roles.first.id)
    person.employee_roles.first.update_attributes(census_employee_id: ce.id, benefit_sponsors_employer_profile_id: abc_profile.id)
    ce
  end
  let!(:enrollment) do
    FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                      household: family.latest_household,
                      coverage_kind: 'health',
                      family: family,
                      aasm_state: 'coverage_selected',
                      effective_on: current_effective_date,
                      kind: 'employer_sponsored',
                      benefit_sponsorship_id: benefit_sponsorship.id,
                      sponsored_benefit_package_id: current_benefit_package.id,
                      sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                      employee_role_id: census_employee.employee_role.id,
                      product: current_benefit_package.sponsored_benefits[0].reference_product,
                      rating_area_id: BSON::ObjectId.new,
                      benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
  end


  context 'plan shopping in termination pending coverage span' do
    before do
      period = initial_application.effective_period.min..TimeKeeper.date_of_record.end_of_month
      initial_application.update_attributes!(termination_reason: 'nonpayment', terminated_on: period.max, effective_period: period)
      initial_application.schedule_enrollment_termination!
      EnrollRegistry[:benefit_application_reinstate].feature.stub(:is_enabled).and_return(true)
      EnrollRegistry[:benefit_application_reinstate]{ {params: {benefit_application: initial_application, options: {transmit_to_carrier: true} } } }
      family.hbx_enrollments.map(&:reload)
      census_employee.reload
      @reinstated_application = benefit_sponsorship.benefit_applications.detect{|app| app.reinstated_id.present?}
      @reinstated_package = @reinstated_application.benefit_packages.first
      @reinstated_enrollment = family.hbx_enrollments.where(sponsored_benefit_package_id: @reinstated_package.id).first
    end

    context 'on purchase' do
      let!(:new_enrollment_purchase) do
        FactoryBot.build(:hbx_enrollment, :with_enrollment_members,
                         household: family.latest_household,
                         coverage_kind: 'health',
                         family: family,
                         aasm_state: 'shopping',
                         effective_on: @reinstated_application.start_on - 1.month,
                         kind: 'employer_sponsored',
                         benefit_sponsorship_id: benefit_sponsorship.id,
                         sponsored_benefit_package_id: current_benefit_package.id,
                         sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                         employee_role_id: census_employee.employee_role.id,
                         product: current_benefit_package.sponsored_benefits[0].reference_product,
                         rating_area_id: BSON::ObjectId.new,
                         predecessor_enrollment_id: enrollment.id,
                         benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
      end

      it 'should create new reinstated enrollment' do
        expect(family.hbx_enrollments.count).to eq 2
        new_enrollment_purchase.select_coverage!
        family.reload

        expect(family.hbx_enrollments.count).to eq 4
        expect(family.hbx_enrollments.where(sponsored_benefit_package_id: @reinstated_package.id, aasm_state: 'coverage_selected').count).to eq 1
      end

      it 'should cancel previous reinstated coverage if any exists' do
        new_enrollment_purchase.select_coverage!
        @reinstated_enrollment.reload
        expect(@reinstated_enrollment.coverage_canceled?).to eq true
      end

      it 'should terminate new purchase with application end date' do
        new_enrollment_purchase.select_coverage!
        new_enrollment_purchase.reload
        expect(new_enrollment_purchase.terminated_on).to eq initial_application.end_on
        expect(new_enrollment_purchase.aasm_state).to eq 'coverage_termination_pending'
      end
    end

    context 'on waive_coverage' do
      let!(:new_enrollment_purchase) do
        FactoryBot.build(:hbx_enrollment, :with_enrollment_members,
                         household: family.latest_household,
                         coverage_kind: 'health',
                         family: family,
                         aasm_state: 'shopping',
                         effective_on: @reinstated_application.start_on - 1.month,
                         kind: 'employer_sponsored',
                         benefit_sponsorship_id: benefit_sponsorship.id,
                         sponsored_benefit_package_id: current_benefit_package.id,
                         sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                         employee_role_id: census_employee.employee_role.id,
                         product: current_benefit_package.sponsored_benefits[0].reference_product,
                         rating_area_id: BSON::ObjectId.new,
                         predecessor_enrollment_id: enrollment.id,
                         benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
      end

      it 'should cancel previous reinstated coverage' do
        expect(family.hbx_enrollments.count).to eq 2
        new_enrollment_purchase.waive_coverage!
        family.reload
        expect(family.hbx_enrollments.count).to eq 3
        @reinstated_enrollment.reload
        expect(@reinstated_enrollment.coverage_canceled?).to eq true
      end
    end
  end
end

describe '.eligible_to_reinstate?', dbclean: :around_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:current_effective_date) {TimeKeeper.date_of_record.beginning_of_month - 6.month}
  let(:person) { FactoryBot.create(:person, :with_employee_role, :with_family) }
  let(:family) { person.primary_family }
  let!(:census_employee) do
    ce = FactoryBot.create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package)
    ce.update_attributes!(employee_role_id: person.employee_roles.first.id)
    person.employee_roles.first.update_attributes(census_employee_id: ce.id, benefit_sponsors_employer_profile_id: abc_profile.id)
    ce
  end
  let!(:enrollment) do
    FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                      household: family.latest_household,
                      coverage_kind: 'health',
                      family: family,
                      aasm_state: 'coverage_selected',
                      effective_on: current_effective_date,
                      kind: 'employer_sponsored',
                      benefit_sponsorship_id: benefit_sponsorship.id,
                      sponsored_benefit_package_id: current_benefit_package.id,
                      sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                      employee_role_id: census_employee.employee_role.id,
                      product: current_benefit_package.sponsored_benefits[0].reference_product,
                      rating_area_id: BSON::ObjectId.new,
                      benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
  end

  context 'reinstate eigible enrollment for a application' do
    before do
      period = initial_application.effective_period.min..TimeKeeper.date_of_record.end_of_month
      initial_application.update_attributes!(termination_reason: 'nonpayment', terminated_on: period.max, effective_period: period)
      initial_application.schedule_enrollment_termination!
      enrollment.reload
    end

    it 'terminated enrollment with term date & reason matchs application' do
      expect(enrollment.eligible_to_reinstate?).to eq true
    end

    it 'canceled enrollment with term reason matchs application' do
      enrollment.update_attributes(aasm_state: 'coverage_canceled')
      enrollment.reload
      expect(enrollment.eligible_to_reinstate?).to eq true
    end

    it 'terminated enrollment with term date greater than application end date' do
      enrollment.update_attributes(terminated_on: TimeKeeper.date_of_record.next_month.end_of_month)
      expect(enrollment.eligible_to_reinstate?).to eq false
    end

    it 'canceled enrollment with start date before application start date' do
      enrollment.update_attributes(effective_on: TimeKeeper.date_of_record.last_year)
      expect(enrollment.eligible_to_reinstate?).to eq false
    end
  end
end

describe '.term_or_cancel_benefit_group_assignment', dbclean: :around_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:current_effective_date) {TimeKeeper.date_of_record.beginning_of_month - 6.month}
  let(:person) { FactoryBot.create(:person, :with_employee_role, :with_family) }
  let(:family) { person.primary_family }
  let!(:census_employee) do
    ce = FactoryBot.create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package)
    ce.update_attributes!(employee_role_id: person.employee_roles.first.id)
    person.employee_roles.first.update_attributes(census_employee_id: ce.id, benefit_sponsors_employer_profile_id: abc_profile.id)
    ce
  end
  let!(:enrollment) do
    FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                      household: family.latest_household,
                      coverage_kind: 'health',
                      family: family,
                      aasm_state: 'coverage_selected',
                      effective_on: current_effective_date,
                      kind: 'employer_sponsored',
                      benefit_sponsorship_id: benefit_sponsorship.id,
                      sponsored_benefit_package_id: current_benefit_package.id,
                      sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                      employee_role_id: census_employee.employee_role.id,
                      product: current_benefit_package.sponsored_benefits[0].reference_product,
                      rating_area_id: BSON::ObjectId.new,
                      benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
  end

  context 'when employment term date outside benefit application end date.' do
    before do
      census_employee.terminate_employment!(TimeKeeper.date_of_record.end_of_month)
      period = initial_application.effective_period.min..initial_application.start_on.next_month.end_of_month
      initial_application.update_attributes!(aasm_state: :terminated, termination_reason: 'nonpayment', terminated_on: period.max, effective_period: period)
      enrollment.terminate_coverage!(initial_application.end_on)
      enrollment.reload
    end

    it 'should update bga with application end date' do
      expect(enrollment.terminated_on).to eq initial_application.end_on
      expect(enrollment.benefit_group_assignment.end_on).to eq initial_application.end_on
    end
  end

  context 'when employment term date inside benefit application end date.' do
    before do
      census_employee.terminate_employment!(TimeKeeper.date_of_record.end_of_month)
      period = initial_application.effective_period.min..TimeKeeper.date_of_record.next_month.end_of_month
      initial_application.update_attributes!(aasm_state: :terminated, termination_reason: 'nonpayment', terminated_on: period.max, effective_period: period)
      enrollment.terminate_coverage!(TimeKeeper.date_of_record.end_of_month)
      enrollment.reload
    end

    it 'should update bga with coverage term date' do
      expect(enrollment.terminated_on).to eq census_employee.coverage_terminated_on
      expect(enrollment.benefit_group_assignment.end_on).to eq census_employee.coverage_terminated_on
    end
  end
end
