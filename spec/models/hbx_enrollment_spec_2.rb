# frozen_string_literal: true

require 'rails_helper'
require 'aasm/rspec'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require File.join(Rails.root, 'spec/shared_contexts/dchbx_product_selection')

describe HbxEnrollment, type: :model, :dbclean => :around_each do
  let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }

  include_context "setup benefit market with market catalogs and product packages" do
    let(:product_kinds)  { [:health, :dental] }
  end

  include_context "setup initial benefit application" do
    let(:dental_sponsored_benefit) { true }
  end

  describe ".renew_benefit", :dbclean => :after_each do
    describe "given an renewing employer just entered open enrollment", dbclean: :after_each do
      describe "with employees who have made the following plan selections previous year:
        - employee A has purchased:
          - One health enrollment (Enrollment 1)
          - One dental enrollment (Enrollment 2)
        - employee B has purchased:
          - One health enrollment (Enrollment 3)
          - One dental waiver (Enrollment 4)
        - employee C has purchased:
          - One health waiver (Enrollment 5)
          - One dental enrollment (Enrollment 6)
        - employee D has purchased:
          - One health waiver (Enrollment 7)
          - One dental waiver (Enrollment 8)
        - employee E has none
      ", dbclean: :after_each do


        let(:census_employees) do
          create_list(:census_employee, 5, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package)
        end

        let(:employee_A) do
          ce = census_employees[0]
          create_person(ce, abc_profile)
        end

        let!(:enrollment_1) do
          create_enrollment(family: employee_A.person.primary_family, benefit_group_assignment: employee_A.census_employee.active_benefit_group_assignment, employee_role: employee_A,
                            submitted_at: current_effective_date - 10.days)
        end

        let!(:enrollment_2) do
          create_enrollment(family: employee_A.person.primary_family, benefit_group_assignment: employee_A.census_employee.active_benefit_group_assignment, employee_role: employee_A,
                            submitted_at: current_effective_date - 10.days, coverage_kind: 'dental')
        end

        let(:employee_B) do
          ce = census_employees[1]
          create_person(ce, abc_profile)
        end

        let!(:enrollment_3) do
          create_enrollment(family: employee_B.person.primary_family, benefit_group_assignment: employee_B.census_employee.active_benefit_group_assignment, employee_role: employee_B,
                            submitted_at: current_effective_date - 10.days)
        end

        let!(:enrollment_4) do
          create_enrollment(family: employee_B.person.primary_family, benefit_group_assignment: employee_B.census_employee.active_benefit_group_assignment, employee_role: employee_B,
                            submitted_at: current_effective_date - 10.days, coverage_kind: 'dental', status: 'inactive')
        end

        let(:employee_C) do
          ce = census_employees[2]
          create_person(ce, abc_profile)
        end

        let!(:enrollment_5) do
          create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C,
                            submitted_at: current_effective_date - 10.days, status: 'inactive')
        end

        let!(:enrollment_6) do
          create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C,
                            submitted_at: current_effective_date - 10.days, coverage_kind: 'dental')
        end

        let(:employee_D) do
          ce = census_employees[3]
          create_person(ce, abc_profile)
        end

        let!(:enrollment_7) do
          create_enrollment(family: employee_D.person.primary_family, benefit_group_assignment: employee_D.census_employee.active_benefit_group_assignment, employee_role: employee_D,
                            submitted_at: current_effective_date - 10.days, status: 'inactive')
        end

        let!(:enrollment_8) do
          create_enrollment(family: employee_D.person.primary_family, benefit_group_assignment: employee_D.census_employee.active_benefit_group_assignment, employee_role: employee_D,
                            submitted_at: current_effective_date - 10.days, coverage_kind: 'dental', status: 'inactive')
        end

        let!(:employee_E) do
          ce = census_employees[3]
          create_person(ce, abc_profile)
        end

        let(:renewal_application) do
          # renewal_effective_date = current_effective_date.next_year
          r_application = initial_application.renew
          r_application.save
          r_application
        end

        let(:initial_benefit_package) { initial_application.benefit_packages[0] }

        let(:renewal_benefit_package) do
          renewal_application.benefit_packages[0]
        end

        before do
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).and_return(100.0)
          renewal_benefit_package.update_attributes(title: initial_benefit_package.title + "(#{renewal_application.effective_period.min.year})")
          renewal_benefit_package.sponsored_benefits.each do |sponsored_benefit|
            allow(sponsored_benefit).to receive(:products).and_return(sponsored_benefit.product_package.products)
          end
          renewal_application
        end

        context 'renewing employee A' do

          before(:each) do
            renewal_benefit_package.renew_member_benefit(census_employees[0])
            family.reload
          end

          let(:family) { employee_A.person.primary_family }
          let(:health_renewals) { family.active_household.hbx_enrollments.renewing.by_health }
          let(:dental_renewals) { family.active_household.hbx_enrollments.renewing.by_dental }

          it 'does renew both health and dental enrollment' do
            expect(health_renewals.size).to eq 1
            expect(health_renewals[0].product).to eq enrollment_1.product.renewal_product
            expect(dental_renewals.size).to eq 1
            expect(dental_renewals[0].product).to eq enrollment_2.product.renewal_product
          end
        end

        context 'renewing employee B' do

          before do
            renewal_benefit_package.renew_member_benefit(census_employees[1])
            family.reload
          end

          let(:family) { employee_B.person.primary_family }
          let(:health_renewals) { family.active_household.hbx_enrollments.renewing.by_health }
          let(:dental_renewals) { family.active_household.hbx_enrollments.by_dental.select(&:renewing_waived?) }

          it 'does renew health coverage and waive dental coverage' do
            expect(health_renewals.size).to eq 1
            expect(health_renewals[0].product).to eq enrollment_3.product.renewal_product
            expect(dental_renewals.size).to eq 1
          end
        end

        context 'renewing employee C' do

          before do
            renewal_benefit_package.renew_member_benefit(census_employees[2])
            family.reload
          end

          let(:family) { employee_C.person.primary_family }
          let(:health_renewals) { family.active_household.hbx_enrollments.by_health.select(&:renewing_waived?) }
          let(:dental_renewals) { family.active_household.hbx_enrollments.renewing.by_dental }

          it 'does renew health coverage and waive dental coverage' do
            expect(health_renewals.size).to eq 1
            expect(dental_renewals.size).to eq 1
            expect(dental_renewals[0].product).to eq enrollment_6.product.renewal_product
          end
        end

        context 'renewing employee D' do

          before do
            renewal_benefit_package.update_attributes(title: initial_benefit_package.title + "(#{renewal_application.effective_period.min.year})")
            renewal_benefit_package.renew_member_benefit(census_employees[3])
            family.reload
          end

          let(:family) { employee_D.person.primary_family }
          let(:passive_renewals) { family.active_household.hbx_enrollments.renewing }
          let(:health_waivers) { family.active_household.hbx_enrollments.by_health.select(&:renewing_waived?) }
          let(:dental_waivers) { family.active_household.hbx_enrollments.by_dental.select(&:renewing_waived?) }

          it 'does renew health coverage and waive dental coverage' do
            expect(passive_renewals).to be_empty
            expect(health_waivers.size).to eq 1
            expect(dental_waivers.size).to eq 1
          end
        end

        context 'renewing employee E' do

          before do
            renewal_benefit_package.renew_member_benefit(census_employees[4])
            family.reload
          end

          let(:family) { employee_E.person.primary_family }
          let(:passive_renewals) { family.active_household.hbx_enrollments.renewing }
          let(:passive_waivers) { family.active_household.hbx_enrollments.select(&:renewing_waived?) }

          it 'does renew health coverage and waive dental coverage' do
            expect(passive_renewals).to be_empty
            expect(passive_waivers).to be_empty
          end
        end


        # rubocop:disable Naming/MethodParameterName
        def create_person(ce, employer_profile)
          person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
          employee_role = FactoryBot.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
          ce.update_attributes!({employee_role_id: employee_role.id})
          Family.find_or_build_from_employee_role(employee_role)
          employee_role
        end
        # rubocop:enable Naming/MethodParameterName

        # rubocop:disable Metrics/ParameterLists
        def create_enrollment(family: nil, benefit_group_assignment: nil, employee_role: nil, status: 'coverage_selected', submitted_at: nil, enrollment_kind: 'open_enrollment', coverage_kind: 'health')
          benefit_package = benefit_group_assignment.benefit_package
          sponsored_benefit = benefit_package.sponsored_benefit_for(coverage_kind.to_sym)
          FactoryBot.create(:hbx_enrollment,:with_enrollment_members,
                            enrollment_members: [family.primary_applicant],
                            household: family.active_household,
                            coverage_kind: coverage_kind,
                            effective_on: benefit_package.start_on,
                            family: family,
                            enrollment_kind: enrollment_kind,
                            kind: "employer_sponsored",
                            submitted_at: submitted_at,
                            employee_role_id: employee_role.id,
                            benefit_sponsorship: benefit_package.benefit_sponsorship,
                            sponsored_benefit_package: benefit_package,
                            sponsored_benefit: sponsored_benefit,
                            benefit_group_assignment_id: benefit_group_assignment.id,
                            product: sponsored_benefit.reference_product,
                            aasm_state: status)
        end
         # rubocop:enable Metrics/ParameterLists
      end
    end
  end
end

describe '#can_make_changes?', :dbclean => :after_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:family) { FactoryBot.build(:family, :with_primary_family_member_and_dependent)}
  let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household) }
  let(:fehb_employer) {double(BenefitSponsors::Organizations::FehbEmployerProfile.new, id: BSON::ObjectId.new)}

  context 'Individual can_make_changes?' do
    it 'should return true if enr is individual market and is active or renewal enrollment' do
      HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES.each do |aasm_state|
        hbx_enrollment.update_attributes(kind: 'individual', aasm_state: aasm_state)
        expect(hbx_enrollment.can_make_changes?).to eq true
      end
    end

    it 'should return false if enr is individual market and is active' do
      %w[shopping coverage_canceled coverage_terminated inactive coverage_expired].each do |aasm_state|
        hbx_enrollment.update_attributes(kind: 'individual', aasm_state: aasm_state)
        expect(hbx_enrollment.can_make_changes?).to eq false
      end
    end
  end

  context 'SHOP can_make_changes?' do
    it 'should return false if enr is in canceled state' do
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_canceled')
      expect(hbx_enrollment.can_make_changes?).to eq false
    end

    it 'should return false if enr is in enrolled state but no benefit package' do
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_enrolled', sponsored_benefit_package_id: nil)
      expect(hbx_enrollment.can_make_changes?).to eq false
    end

    it 'should return false if enr has benefit package but in expired state' do
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_expired', sponsored_benefit_package_id: current_benefit_package.id)
      expect(hbx_enrollment.can_make_changes?).to eq false
    end

    it 'should return true if enr is active and in open enrollment period' do
      allow(hbx_enrollment).to receive(:open_enrollment_period_available?).and_return true
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_enrolled', sponsored_benefit_package_id: current_benefit_package.id)
      expect(hbx_enrollment.can_make_changes?).to eq true
    end

    it 'should return false if enr is active and is not in open enrollment period' do
      allow(hbx_enrollment).to receive(:open_enrollment_period_available?).and_return false
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_enrolled', sponsored_benefit_package_id: current_benefit_package.id)
      expect(hbx_enrollment.can_make_changes?).to eq false
    end

    it 'should return false if enr is active and is not in open enrollment period but family has no active shop sep' do
      allow(hbx_enrollment).to receive(:open_enrollment_period_available?).and_return false
      allow(hbx_enrollment.family).to receive(:earliest_effective_shop_sep).and_return nil
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_enrolled', sponsored_benefit_package_id: current_benefit_package.id)
      expect(hbx_enrollment.can_make_changes?).to eq false
    end

    it 'should return true if enr is active and is not in open enrollment period and family has active shop sep which falls under benefit package effective period' do
      allow(hbx_enrollment).to receive(:open_enrollment_period_available?).and_return false
      allow(hbx_enrollment.family).to receive(:earliest_effective_shop_sep).and_return(double("SpecialEnrollmentPeriod", effective_on: current_benefit_package.start_on,
                                                                                                                         start_on: current_benefit_package.start_on, end_on: current_benefit_package.end_on))
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_enrolled', sponsored_benefit_package_id: current_benefit_package.id)
      expect(hbx_enrollment.can_make_changes?).to eq true
    end

    it 'should return true if enr is active and the employee is in new hire open enrollment period' do
      allow(hbx_enrollment).to receive(:open_enrollment_period_available?).and_return false
      allow(hbx_enrollment).to receive(:special_enrollment_period_available?).and_return false
      allow(hbx_enrollment).to receive(:new_hire_enrollment_period_available?).and_return true
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_enrolled', sponsored_benefit_package_id: current_benefit_package.id)
      expect(hbx_enrollment.can_make_changes?).to eq true
    end

    it 'should return false if enr is active and the employee is not in new hire open enrollment period' do
      allow(hbx_enrollment).to receive(:open_enrollment_period_available?).and_return false
      allow(hbx_enrollment).to receive(:special_enrollment_period_available?).and_return false
      allow(hbx_enrollment).to receive(:new_hire_enrollment_period_available?).and_return false
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_enrolled', sponsored_benefit_package_id: current_benefit_package.id)
      expect(hbx_enrollment.can_make_changes?).to eq false
    end

    it 'should return true if Congressional active enrollment is in open enrollment period' do
      allow(hbx_enrollment).to receive(:fehb_profile).and_return(fehb_employer)
      allow(hbx_enrollment).to receive(:open_enrollment_period_available?).and_return true
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_enrolled', sponsored_benefit_package_id: current_benefit_package.id)
      expect(hbx_enrollment.can_make_changes?).to eq true
    end

    it 'should return true if Congressional active enrollment and the employee is in new hire enrollment period' do
      allow(hbx_enrollment).to receive(:fehb_profile).and_return(fehb_employer)
      allow(hbx_enrollment).to receive(:open_enrollment_period_available?).and_return false
      allow(hbx_enrollment).to receive(:special_enrollment_period_available?).and_return false
      allow(hbx_enrollment).to receive(:new_hire_enrollment_period_available?).and_return true
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_enrolled', sponsored_benefit_package_id: current_benefit_package.id)
      expect(hbx_enrollment.can_make_changes?).to eq true
    end

    it 'should return true if Congressional active enrollment and the employee is in special enrollment period' do
      allow(hbx_enrollment).to receive(:fehb_profile).and_return(fehb_employer)
      allow(hbx_enrollment).to receive(:open_enrollment_period_available?).and_return false
      allow(hbx_enrollment).to receive(:special_enrollment_period_available?).and_return true
      allow(hbx_enrollment).to receive(:new_hire_enrollment_period_available?).and_return false
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_enrolled', sponsored_benefit_package_id: current_benefit_package.id)
      expect(hbx_enrollment.can_make_changes?).to eq true
    end

    it 'should return false if enr has benefit package and oe period but in expired state' do
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_expired', sponsored_benefit_package_id: current_benefit_package.id)
      allow(hbx_enrollment).to receive(:open_enrollment_period_available?).and_return true
      allow(hbx_enrollment).to receive(:special_enrollment_period_available?).and_return true
      expect(hbx_enrollment.can_make_changes?).to eq false
    end

    it 'should return false if enr has benefit package and oe period but in terminated state' do
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: "coverage_terminated", sponsored_benefit_package_id: current_benefit_package.id)
      allow(hbx_enrollment).to receive(:open_enrollment_period_available?).and_return true
      allow(hbx_enrollment).to receive(:special_enrollment_period_available?).and_return true
      expect(hbx_enrollment.can_make_changes?).to eq false
    end
  end
end

describe '#has_at_least_one_aptc_eligible_member?' do
  let(:person) { FactoryBot.create(:person, :with_consumer_role)}
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:household) { family.active_household}
  let!(:tax_household) {FactoryBot.create(:tax_household,  effective_ending_on: nil, household: household)}
  let!(:tax_household_member) {FactoryBot.create(:tax_household_member, tax_household: tax_household)}
  let!(:hbx_enrollment) {FactoryBot.create(:hbx_enrollment, effective_on: TimeKeeper.date_of_record.beginning_of_year, family: person.primary_family)}
  let!(:eligibility_kinds1) {{"is_ia_eligible" => true}}
  let!(:eligibility_kinds2) {{"is_ia_eligible" => false}}
  let(:effective_on_year) {hbx_enrollment.effective_on.year}
  context 'aptc eligible member on tax household' do
    it 'should return true' do
      tax_household_member.update_attributes(eligibility_kinds1)
      hbx_enrollment.reload
      expect(hbx_enrollment.has_at_least_one_aptc_eligible_member?(effective_on_year)).to eq true
    end
  end
  context 'no aptc eligible member on tax household' do
    it 'should return false' do
      tax_household_member.update_attributes(eligibility_kinds2)
      hbx_enrollment.reload
      expect(hbx_enrollment.has_at_least_one_aptc_eligible_member?(effective_on_year)).to eq false
    end
  end
end

describe "#notify_enrollment_cancel_or_termination_event", :dbclean => :after_each do
  let(:family) { FactoryBot.build(:family, :with_primary_family_member_and_dependent)}
  let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family,household: family.active_household, kind: "employer_sponsored", aasm_state: "coverage_terminated") }
  let!(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }

  it "should notify event" do # loud transaction
    expect(hbx_enrollment).to receive(:notify).with(
      "acapi.info.events.hbx_enrollment.terminated",
      {
        :reply_to => glue_event_queue_name,
        "hbx_enrollment_id" => hbx_enrollment.hbx_id,
        "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
        "is_trading_partner_publishable" => true
      }
    )
    hbx_enrollment.notify_enrollment_cancel_or_termination_event(true)
  end

  it "should notify event, with trading_partner_publishable flag false" do # silent transaction
    expect(hbx_enrollment).to receive(:notify).with(
      "acapi.info.events.hbx_enrollment.terminated",
      {
        :reply_to => glue_event_queue_name,
        "hbx_enrollment_id" => hbx_enrollment.hbx_id,
        "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
        "is_trading_partner_publishable" => false
      }
    )
    hbx_enrollment.notify_enrollment_cancel_or_termination_event(false)
  end
end

describe HbxEnrollment, dbclean: :after_all do
  let!(:ivl_person)       { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let!(:ivl_family)       { FactoryBot.create(:family, :with_primary_family_member, person: ivl_person) }
  let!(:ivl_enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      household: ivl_family.active_household,
      effective_on: TimeKeeper.date_of_record.beginning_of_year,
      family: ivl_family,
      kind: "individual",
      is_any_enrollment_member_outstanding: true,
      aasm_state: "coverage_selected"
    )
  end

  let!(:ivl_enrollment_member)  do
    FactoryBot.create(:hbx_enrollment_member, is_subscriber: true,
                                              applicant_id: ivl_family.primary_applicant.id, hbx_enrollment: ivl_enrollment,
                                              eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record)
  end

  context ".is_ivl_actively_outstanding?" do
    it "should return true" do
      allow(ivl_enrollment).to receive(:is_effective_in_current_year?).and_return true
      ivl_person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
      ivl_enrollment.save!
      expect(ivl_enrollment.is_ivl_actively_outstanding?).to be_truthy
    end

    it "should return false" do
      expect(ivl_enrollment.is_ivl_actively_outstanding?).to be_falsey
    end
  end

  context ".enrollments_for_display" do
    it "should return enrollments for display matching the family id" do
      expect(HbxEnrollment.enrollments_for_display(ivl_family.id).map{|a| a['_id']}).to include(ivl_enrollment.id)
    end
  end

  context "for set_is_any_enrollment_member_outstanding" do
    it "should return true for is_any_enrollment_member_outstanding" do
      ivl_person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
      ivl_enrollment.save!
      expect(ivl_enrollment.is_any_enrollment_member_outstanding).to be_truthy
    end

    it "should return false for is_any_enrollment_member_outstanding" do
      ivl_enrollment.save!
      expect(ivl_enrollment.is_any_enrollment_member_outstanding).to be_falsey
    end
  end
end
