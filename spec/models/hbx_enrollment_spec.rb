# frozen_string_literal: true

require 'rails_helper'
require 'aasm/rspec'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require File.join(Rails.root, 'spec/shared_contexts/dchbx_product_selection')

describe ".propogate_cancel" do
  include_context 'family with previous enrollment for termination and passive renewal'
  let(:current_year) { TimeKeeper.date_of_record.year }
  let(:active_coverage) { expired_enrollment }

  context "individual market" do
    before do
      family.hbx_enrollments.where(effective_on: TimeKeeper.date_of_record.next_year.beginning_of_year).first.update_attributes(aasm_state: "auto_renewing")
      active_coverage.update_attributes(aasm_state: :coverage_selected)
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 11, 1))
    end

    context "cancel_coverage" do
      it 'should cancel renewal enrollment when canceling active enrollment' do
        active_coverage.cancel_coverage!
        family.reload
        renewal_enrollment = family.hbx_enrollments.where(effective_on: TimeKeeper.date_of_record.next_year.beginning_of_year).first
        expect(renewal_enrollment.aasm_state).to eq "coverage_canceled"
        expect(active_coverage.aasm_state).to eq "coverage_canceled"
      end

      it 'should cancel renewal enrollment when canceling expired enrollment' do
        active_coverage.update_attributes(aasm_state: 'coverage_expired')
        active_coverage.reload
        expect(active_coverage.aasm_state).to eq 'coverage_expired'
        active_coverage.cancel_coverage!
        family.reload
        renewal_enrollment = family.hbx_enrollments.where(effective_on: TimeKeeper.date_of_record.next_year.beginning_of_year).first
        expect(renewal_enrollment.aasm_state).to eq "coverage_canceled"
        expect(active_coverage.aasm_state).to eq "coverage_canceled"
      end
    end

    context "cancel_for_non_payment" do
      it 'should cancel renewal enrollment when canceling active enrollment' do
        active_coverage.cancel_for_non_payment!
        family.reload
        renewal_enrollment = family.hbx_enrollments.where(effective_on: TimeKeeper.date_of_record.next_year.beginning_of_year).first
        expect(renewal_enrollment.aasm_state).to eq "coverage_canceled"
        expect(active_coverage.aasm_state).to eq "coverage_canceled"
      end

      it 'should cancel renewal enrollment when canceling expired enrollment' do
        active_coverage.update_attributes(aasm_state: 'coverage_expired')
        active_coverage.reload
        expect(active_coverage.aasm_state).to eq 'coverage_expired'
        active_coverage.cancel_for_non_payment!
        family.reload
        renewal_enrollment = family.hbx_enrollments.where(effective_on: TimeKeeper.date_of_record.next_year.beginning_of_year).first
        expect(renewal_enrollment.aasm_state).to eq "coverage_canceled"
        expect(active_coverage.aasm_state).to eq "coverage_canceled"
      end
    end
  end

  context "shop market" do
    before do
      family.hbx_enrollments.where(effective_on: TimeKeeper.date_of_record.next_year.beginning_of_year).first.update_attributes(aasm_state: "auto_renewing")
      active_coverage.update_attributes(aasm_state: :coverage_selected, kind: 'employer_sponsored')
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 11, 1))
      active_coverage.cancel_coverage!
      family.reload
    end

    it 'should not cancel renewal enrollment when canceling active enrollment' do
      renewal_enrollment = family.hbx_enrollments.where(effective_on: TimeKeeper.date_of_record.next_year.beginning_of_year).first
      expect(renewal_enrollment.aasm_state).to eq "auto_renewing"
      expect(active_coverage.aasm_state).to eq "coverage_canceled"
    end
  end

  describe 'exclude_child_only_offering' do
    let(:child_only_product) { double('Child Only Product', :allows_child_only_offering? => true, :allows_adult_and_child_only_offering? => false) }
    let(:regular_product) { double('Product', :allows_child_only_offering? => false, :allows_adult_and_child_only_offering? => false) }
    let(:elected_plans) { [child_only_product, regular_product] }
    let(:enrollment) { FactoryBot.build(:hbx_enrollment, family: family)}

    before do
      allow_any_instance_of(BenefitCoveragePeriod).to receive(:elected_plans_by_enrollment_members).and_return(elected_plans)
    end

    subject do
      enrollment.decorated_elected_plans(coverage_kind)
    end

    context 'when disabled' do
      before do
        EnrollRegistry[:exclude_child_only_offering].feature.stub(:is_enabled).and_return(false)
      end

      context 'when members greater than 18 exists' do
        before do
          allow(enrollment).to receive(:any_member_greater_than_18?).and_return true
        end

        context 'for health product' do
          let(:coverage_kind) { 'health' }

          it 'should not exclude child only offering' do
            expect(subject.size).to eq 2
          end
        end

        context 'for dental product' do
          let(:coverage_kind) { 'dental' }

          it 'should not exclude child only offering' do
            expect(subject.size).to eq 2
          end
        end
      end

      context 'when all the members are < 18' do
        before do
          allow(enrollment).to receive(:any_member_greater_than_18?).and_return false
        end

        context 'for health product' do
          let(:coverage_kind) { 'health' }

          it 'should not exclude child only offering' do
            expect(subject.size).to eq 2
          end
        end

        context 'for dental product' do
          let(:coverage_kind) { 'dental' }

          it 'should not exclude child only offering' do
            expect(subject.size).to eq 2
          end
        end
      end
    end

    context 'when enabled' do
      before do
        EnrollRegistry[:exclude_child_only_offering].feature.stub(:is_enabled).and_return(true)
      end

      context 'when members greater than 18 exists' do
        before do
          allow(enrollment).to receive(:any_member_greater_than_18?).and_return true
        end

        context 'for health product' do
          let(:coverage_kind) { 'health' }

          it 'should not exclude child only offering' do
            expect(subject.size).to eq 2
          end
        end

        context 'for dental product' do
          let(:coverage_kind) { 'dental' }

          it 'should exclude child only offering' do
            expect(subject.size).to eq 1
          end
        end
      end

      context 'when all the members are < 18' do
        before do
          allow(enrollment).to receive(:any_member_greater_than_18?).and_return false
        end

        context 'for health product' do
          let(:coverage_kind) { 'health' }

          it 'should not exclude child only offering' do
            expect(subject.size).to eq 2
          end
        end

        context 'for dental product' do
          let(:coverage_kind) { 'dental' }

          it 'should not exclude child only offering' do
            expect(subject.size).to eq 2
          end
        end
      end
    end
  end

  describe 'allows_adult_and_child_only_offering' do
    let(:adult_and_child_product) { double('Adult & Child Product', :allows_adult_and_child_only_offering? => true, :allows_child_only_offering? => false) }
    let(:regular_product) { double('Product', :allows_adult_and_child_only_offering? => false, :allows_child_only_offering? => false) }
    let(:elected_plans) { [adult_and_child_product, regular_product] }
    let(:enrollment) { FactoryBot.build(:hbx_enrollment, family: family)}

    before do
      allow_any_instance_of(BenefitCoveragePeriod).to receive(:elected_plans_by_enrollment_members).and_return(elected_plans)
    end

    subject do
      enrollment.decorated_elected_plans(coverage_kind)
    end

    context 'when disabled' do
      before do
        EnrollRegistry[:exclude_adult_and_child_only_offering].feature.stub(:is_enabled).and_return(false)
      end

      context 'when members greater than 18 exists' do
        before do
          allow(enrollment).to receive(:any_member_greater_than_18?).and_return true
        end

        context 'for health product' do
          let(:coverage_kind) { 'health' }

          it 'should not exclude child & adult only offering' do
            expect(subject.size).to eq 2
          end
        end

        context 'for dental product' do
          let(:coverage_kind) { 'dental' }

          it 'should not exclude child & adult only offering' do
            expect(subject.size).to eq 2
          end
        end
      end

      context 'when all the members are < 18' do
        before do
          allow(enrollment).to receive(:any_member_greater_than_18?).and_return false
        end

        context 'for health product' do
          let(:coverage_kind) { 'health' }

          it 'should not exclude adult & child only offering' do
            expect(subject.size).to eq 2
          end
        end

        context 'for dental product' do
          let(:coverage_kind) { 'dental' }

          it 'should not exclude adult & child only offering' do
            expect(subject.size).to eq 2
          end
        end
      end
    end

    context 'when enabled' do
      before do
        EnrollRegistry[:exclude_adult_and_child_only_offering].feature.stub(:is_enabled).and_return(true)
      end

      context 'when members greater than 18 exists' do
        before do
          allow(enrollment).to receive(:any_member_greater_than_18?).and_return true
        end

        context 'for health product' do
          let(:coverage_kind) { 'health' }

          it 'should not exclude adult & child only offering' do
            expect(subject.size).to eq 2
          end
        end

        context 'for dental product' do
          let(:coverage_kind) { 'dental' }

          it 'should not exclude adult & child only offering' do
            expect(subject.size).to eq 2
          end
        end
      end

      context 'when all the members are < 18' do
        before do
          allow(enrollment).to receive(:any_member_greater_than_18?).and_return false
        end

        context 'for health product' do
          let(:coverage_kind) { 'health' }

          it 'should not exclude adult & child only offering' do
            expect(subject.size).to eq 2
          end
        end

        context 'for dental product' do
          let(:coverage_kind) { 'dental' }

          it 'should exclude adult & child only offering' do
            expect(subject.size).to eq 1
          end
        end
      end
    end
  end

  describe 'trigger_enrollment_notice' do
    let(:person) { create(:person, :with_consumer_role) }
    let(:family) { create(:family, :with_primary_family_member, person: person)}
    let(:effective_on) { TimeKeeper.date_of_record.beginning_of_month }

    context 'when shop market' do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"

      let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile) }
      let(:employee_role) { FactoryBot.create(:employee_role, person: person, census_employee: census_employee, employer_profile: benefit_sponsorship.profile) }


      let(:shop_enrollment) do
        FactoryBot.build(
          :hbx_enrollment,
          :shop,
          :with_enrollment_members,
          :with_product,
          coverage_kind: "health",
          family: family,
          employee_role: employee_role,
          effective_on: effective_on,
          aasm_state: 'shopping',
          benefit_sponsorship_id: benefit_sponsorship.id,
          sponsored_benefit_package_id: current_benefit_package.id,
          sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
          employee_role_id: employee_role.id,
          benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id
        )
      end

      it 'should not trigger enr notice' do
        expect(Services::IvlEnrollmentService).not_to receive(:new)
        shop_enrollment.select_coverage!
      end
    end

    context 'when ivl market' do
      let(:ivl_enrollment) do
        FactoryBot.build(
          :hbx_enrollment,
          :individual_shopping,
          :with_enrollment_members,
          :with_product,
          family: family,
          consumer_role: person.consumer_role,
          coverage_kind: "health",
          effective_on: effective_on
        )
      end

      it 'should trigger enr notice' do
        expect(Services::IvlEnrollmentService).to receive_message_chain('new.trigger_enrollment_notice').with(ivl_enrollment)
        ivl_enrollment.select_coverage!
      end
    end
  end
end

describe '.reset_dates_on_previously_covered_members' do

  let!(:person1) do
    FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role,
                      first_name: 'test10', last_name: 'test30', gender: 'male')
  end

  let!(:person2) do
    person = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role,
                               first_name: 'test', last_name: 'test10', gender: 'male')
    person1.ensure_relationship_with(person, 'child')
    person
  end

  let!(:family) do
    FactoryBot.create(:family, :with_primary_family_member, person: person1)
  end

  let!(:dependent_family_member) do
    FactoryBot.create(:family_member, family: family, person: person2)
  end

  let(:household) { FactoryBot.create(:household, family: family) }
  let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}
  let(:effective_on) { TimeKeeper.date_of_record.beginning_of_year}
  let(:new_effective_on) { Date.new(effective_on.year, 6, 1) }

  let!(:active_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      family: family,
                      household: family.active_household,
                      kind: "individual",
                      coverage_kind: "health",
                      product: product,
                      aasm_state: 'coverage_selected',
                      effective_on: effective_on,
                      hbx_enrollment_members: [
                        FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, eligibility_date: effective_on, coverage_start_on: effective_on, is_subscriber: true)
                      ])
  end

  let!(:shopping_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      family: family,
                      effective_on: new_effective_on,
                      household: family.active_household,
                      kind: "individual",
                      coverage_kind: "health",
                      aasm_state: 'shopping',
                      hbx_enrollment_members: [
                        FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, eligibility_date: new_effective_on, coverage_start_on: new_effective_on, is_subscriber: true),
                        FactoryBot.build(:hbx_enrollment_member, applicant_id: dependent_family_member.id, eligibility_date: new_effective_on, coverage_start_on: new_effective_on, is_subscriber: false)
                      ])
  end

  let(:primary_enrollment_member) { shopping_enrollment.hbx_enrollment_members.detect{|enm| enm.applicant_id == family.primary_applicant.id} }
  let(:dependent_enrollment_member) { shopping_enrollment.hbx_enrollment_members.detect{|enm| enm.applicant_id != family.primary_applicant.id} }

  context 'when same product passed' do
    let(:new_product) { product }

    it 'should reset coverage_start_on dates on previously enrolled members' do
      expect(primary_enrollment_member.coverage_start_on).to eq new_effective_on
      expect(dependent_enrollment_member.coverage_start_on).to eq new_effective_on

      shopping_enrollment.reset_dates_on_previously_covered_members(new_product)

      expect(primary_enrollment_member.reload.coverage_start_on).to eq effective_on
      expect(dependent_enrollment_member.reload.coverage_start_on).to eq new_effective_on
    end
  end

  context 'when different product passed' do

    let(:new_product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '02')}

    it 'should not reset coverage_start_on dates on previously enrolled members' do
      expect(primary_enrollment_member.coverage_start_on).to eq new_effective_on
      expect(dependent_enrollment_member.coverage_start_on).to eq new_effective_on

      shopping_enrollment.reset_dates_on_previously_covered_members(new_product)

      expect(primary_enrollment_member.reload.coverage_start_on).to eq new_effective_on
      expect(dependent_enrollment_member.reload.coverage_start_on).to eq new_effective_on
    end
  end


end

describe '.covered_members_first_names' do
  let!(:person1) do
    FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role,
                      first_name: 'primary', last_name: 'test30', gender: 'male')
  end

  let!(:person2) do
    person = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role,
                               first_name: 'dependent', last_name: 'test30', gender: 'male')
    person1.ensure_relationship_with(person, 'child')
    person
  end

  let!(:family) do
    FactoryBot.create(:family, :with_primary_family_member, person: person1)
  end

  let!(:dependent_family_member) do
    FactoryBot.create(:family_member, family: family, person: person2)
  end

  let(:household) { FactoryBot.create(:household, family: family) }
  let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}
  let(:effective_on) { TimeKeeper.date_of_record.beginning_of_year}
  let(:new_effective_on) { Date.new(effective_on.year, 6, 1) }

  context 'when primary is the subscriber' do
    let!(:active_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        kind: "individual",
                        coverage_kind: "health",
                        product: product,
                        aasm_state: 'coverage_selected',
                        effective_on: effective_on,
                        hbx_enrollment_members: [
                          FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, eligibility_date: new_effective_on, coverage_start_on: new_effective_on, is_subscriber: true),
                          FactoryBot.build(:hbx_enrollment_member, applicant_id: dependent_family_member.id, eligibility_date: new_effective_on, coverage_start_on: new_effective_on, is_subscriber: false)
                        ])
    end

    it 'should list primary first in the array' do
      names = active_enrollment.covered_members_first_names
      expect(names).to eq ["primary", "dependent"]
    end
  end

  context 'when dependent is the subscriber' do
    let!(:active_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        kind: "individual",
                        coverage_kind: "health",
                        product: product,
                        aasm_state: 'coverage_selected',
                        effective_on: effective_on,
                        hbx_enrollment_members: [
                          FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, eligibility_date: new_effective_on, coverage_start_on: new_effective_on, is_subscriber: false),
                          FactoryBot.build(:hbx_enrollment_member, applicant_id: dependent_family_member.id, eligibility_date: new_effective_on, coverage_start_on: new_effective_on, is_subscriber: true)
                        ])
    end

    it 'should list dependent first in the array' do
      names = active_enrollment.covered_members_first_names
      expect(names).to eq ["dependent", "primary"]
    end
  end
end

describe 'update_osse_childcare_subsidy', dbclean: :around_each do
  include_context "setup benefit market with market catalogs and product packages"
  let(:current_effective_date) { (TimeKeeper.date_of_record - 2.months).beginning_of_month }

  include_context "setup initial benefit application"

  let(:person) { FactoryBot.create(:person, :with_employee_role, :with_family) }
  let(:family) { person.primary_family }
  let!(:census_employee) do
    ce = FactoryBot.create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package)
    ce.update_attributes!(employee_role_id: person.employee_roles.first.id)
    person.employee_roles.first.update_attributes(census_employee_id: ce.id, benefit_sponsors_employer_profile_id: abc_profile.id)
    ce
  end
  let(:employee_role) { census_employee.employee_role.reload }
  let(:effective_on) { initial_application.start_on.to_date }
  let(:coverage_kind) { "health" }

  let(:shop_enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      :shop,
      :with_enrollment_members,
      :with_product,
      coverage_kind: coverage_kind,
      family: person.primary_family,
      employee_role: employee_role,
      effective_on: (effective_on + 3.months),
      aasm_state: 'shopping',
      rating_area: rating_area,
      hbx_enrollment_members: [hbx_enrollment_member],
      benefit_sponsorship_id: benefit_sponsorship.id,
      sponsored_benefit_package_id: current_benefit_package.id,
      sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
      employee_role_id: employee_role.id,
      benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id
    )
  end

  let(:hbx_enrollment_member) do
    FactoryBot.build(
      :hbx_enrollment_member,
      is_subscriber: true,
      applicant_id: family.primary_family_member.id,
      coverage_start_on: TimeKeeper.date_of_record.beginning_of_month,
      eligibility_date: TimeKeeper.date_of_record.beginning_of_month
    )
  end

  let(:hios_id) { EnrollRegistry["lowest_cost_silver_product_#{effective_on.year}"].item }
  let!(:lcsp) do
    create(
      :benefit_markets_products_health_products_health_product,
      application_period: (effective_on.beginning_of_year..effective_on.end_of_year),
      hios_id: hios_id
    )
  end
  let(:age) { person.age_on(effective_on) }
  let(:site_key) { EnrollRegistry[:enroll_app].setting(:site_key).item.upcase }
  let(:premium) { 214.85 }

  context 'whem employee is eligible for OSSE' do
    before do
      allow_any_instance_of(EmployeeRole).to receive(:osse_eligible?).and_return(true)
      allow_any_instance_of(HbxEnrollment).to receive(:shop_osse_eligibility_is_enabled?).and_return(true)
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).and_return(premium)
      shop_enrollment.update_osse_childcare_subsidy
    end

    it 'should update OSSE subsidy' do
      expect(shop_enrollment.reload.eligible_child_care_subsidy.to_f).to eq(premium)
    end

    context 'when enrollment is dental' do
      let(:coverage_kind) { :dental }

      it 'should not update OSSE subsidy' do
        expect(shop_enrollment.reload.eligible_child_care_subsidy.to_f).to eq(0.00)
      end
    end
  end

  context 'when employee is not eligible for OSSE' do
    before do
      allow_any_instance_of(EmployeeRole).to receive(:osse_eligible?).and_return(false)
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).and_return(premium)
      shop_enrollment.update_osse_childcare_subsidy
    end

    it 'should not update OSSE subsidy' do
      expect(shop_enrollment.reload.eligible_child_care_subsidy.to_f).to eq(0.00)
    end

    context 'when enrollment is dental' do
      let(:coverage_kind) { :dental }

      it 'should not update OSSE subsidy' do
        expect(shop_enrollment.reload.eligible_child_care_subsidy.to_f).to eq(0.00)
      end
    end
  end

  context 'when employer is not eligible to sponsor OSSE in a given year' do
    before do
      allow_any_instance_of(EmployeeRole).to receive(:osse_eligible?).and_return(true)
      allow_any_instance_of(HbxEnrollment).to receive(:shop_osse_eligibility_is_enabled?).and_return(false)
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).and_return(premium)
      shop_enrollment.update_osse_childcare_subsidy
    end

    it 'should not update OSSE subsidy' do
      expect(shop_enrollment.reload.eligible_child_care_subsidy.to_f).to eq(0.00)
    end
  end
end
