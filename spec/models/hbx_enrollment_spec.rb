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


        let(:census_employees) {
          create_list(:census_employee, 5, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package)
        }

        let(:employee_A) {
          ce = census_employees[0]
          create_person(ce, abc_profile)
        }

        let!(:enrollment_1) {
          create_enrollment(family: employee_A.person.primary_family, benefit_group_assignment: employee_A.census_employee.active_benefit_group_assignment, employee_role: employee_A,
            submitted_at: current_effective_date - 10.days)
        }

        let!(:enrollment_2) {
          create_enrollment(family: employee_A.person.primary_family, benefit_group_assignment: employee_A.census_employee.active_benefit_group_assignment, employee_role: employee_A,
            submitted_at: current_effective_date - 10.days, coverage_kind: 'dental')
        }

        let(:employee_B) {
          ce = census_employees[1]
          create_person(ce, abc_profile)
        }

        let!(:enrollment_3) {
          create_enrollment(family: employee_B.person.primary_family, benefit_group_assignment: employee_B.census_employee.active_benefit_group_assignment, employee_role: employee_B,
            submitted_at: current_effective_date - 10.days)
        }

        let!(:enrollment_4) {
          create_enrollment(family: employee_B.person.primary_family, benefit_group_assignment: employee_B.census_employee.active_benefit_group_assignment, employee_role: employee_B,
            submitted_at: current_effective_date - 10.days, coverage_kind: 'dental', status: 'inactive')
        }

        let(:employee_C) {
          ce = census_employees[2]
          create_person(ce, abc_profile)
        }

        let!(:enrollment_5) {
          create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C,
            submitted_at: current_effective_date - 10.days, status: 'inactive')
        }

        let!(:enrollment_6) {
          create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C,
            submitted_at: current_effective_date - 10.days, coverage_kind: 'dental')
        }

        let(:employee_D) {
          ce = census_employees[3]
          create_person(ce, abc_profile)
        }

        let!(:enrollment_7) {
          create_enrollment(family: employee_D.person.primary_family, benefit_group_assignment: employee_D.census_employee.active_benefit_group_assignment, employee_role: employee_D,
            submitted_at: current_effective_date - 10.days, status: 'inactive')
        }

        let!(:enrollment_8) {
          create_enrollment(family: employee_D.person.primary_family, benefit_group_assignment: employee_D.census_employee.active_benefit_group_assignment, employee_role: employee_D,
            submitted_at: current_effective_date - 10.days, coverage_kind: 'dental', status: 'inactive')
        }

        let!(:employee_E) {
          ce = census_employees[3]
          create_person(ce, abc_profile)
        }

        let(:renewal_application) {
          renewal_effective_date = current_effective_date.next_year
          r_application = initial_application.renew
          r_application.save
          r_application
        }

        let(:initial_benefit_package) { initial_application.benefit_packages[0] }

        let(:renewal_benefit_package) {
          renewal_application.benefit_packages[0]
        }

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
          let(:dental_renewals) { family.active_household.hbx_enrollments.by_dental.select{|en| en.renewing_waived?} }

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
          let(:health_renewals) { family.active_household.hbx_enrollments.by_health.select{|en| en.renewing_waived?} }
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
          let(:health_waivers) { family.active_household.hbx_enrollments.by_health.select{|en| en.renewing_waived?} }
          let(:dental_waivers) { family.active_household.hbx_enrollments.by_dental.select{|en| en.renewing_waived?} }

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
          let(:passive_waivers) { family.active_household.hbx_enrollments.select{|en| en.renewing_waived?} }

          it 'does renew health coverage and waive dental coverage' do
            expect(passive_renewals).to be_empty
            expect(passive_waivers).to be_empty
          end
        end

        def create_person(ce, employer_profile)
          person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
          employee_role = FactoryBot.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
          ce.update_attributes!({employee_role_id: employee_role.id})
          Family.find_or_build_from_employee_role(employee_role)
          employee_role
        end

        def create_enrollment(family: nil, benefit_group_assignment: nil, employee_role: nil, status: 'coverage_selected', submitted_at: nil, enrollment_kind: 'open_enrollment', effective_date: nil, coverage_kind: 'health')
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
            aasm_state: status
            )
        end
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
        expect(hbx_enrollment.can_make_changes?). to eq true
      end
    end

    it 'should return false if enr is individual market and is active' do
      %w[shopping coverage_canceled coverage_terminated inactive coverage_expired].each do |aasm_state|
        hbx_enrollment.update_attributes(kind: 'individual', aasm_state: aasm_state)
        expect(hbx_enrollment.can_make_changes?). to eq false
      end
    end
  end

  context 'SHOP can_make_changes?' do
    it 'should return false if enr is in canceled state' do
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_canceled')
      expect(hbx_enrollment.can_make_changes?). to eq false
    end

    it 'should return false if enr is in enrolled state but no benefit package' do
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_enrolled', sponsored_benefit_package_id: nil)
      expect(hbx_enrollment.can_make_changes?). to eq false
    end

    it 'should return false if enr has benefit package but in expired state' do
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_expired', sponsored_benefit_package_id: current_benefit_package.id)
      expect(hbx_enrollment.can_make_changes?). to eq false
    end

    it 'should return true if enr is active and in open enrollment period' do
      allow(hbx_enrollment).to receive(:open_enrollment_period_available?).and_return true
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_enrolled', sponsored_benefit_package_id: current_benefit_package.id)
      expect(hbx_enrollment.can_make_changes?). to eq true
    end

    it 'should return false if enr is active and is not in open enrollment period' do
      allow(hbx_enrollment).to receive(:open_enrollment_period_available?).and_return false
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_enrolled', sponsored_benefit_package_id: current_benefit_package.id)
      expect(hbx_enrollment.can_make_changes?). to eq false
    end

    it 'should return false if enr is active and is not in open enrollment period but family has no active shop sep' do
      allow(hbx_enrollment).to receive(:open_enrollment_period_available?).and_return false
      allow(hbx_enrollment.family).to receive(:earliest_effective_shop_sep).and_return nil
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_enrolled', sponsored_benefit_package_id: current_benefit_package.id)
      expect(hbx_enrollment.can_make_changes?). to eq false
    end

    it 'should return true if enr is active and is not in open enrollment period and family has active shop sep which falls under benefit package effective period' do
      allow(hbx_enrollment).to receive(:open_enrollment_period_available?).and_return false
      allow(hbx_enrollment.family).to receive(:earliest_effective_shop_sep).and_return(double("SpecialEnrollmentPeriod", effective_on: current_benefit_package.start_on,
                                                                                                                         start_on: current_benefit_package.start_on, end_on: current_benefit_package.end_on))
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_enrolled', sponsored_benefit_package_id: current_benefit_package.id)
      expect(hbx_enrollment.can_make_changes?). to eq true
    end

    it 'should return true if enr is active and the employee is in new hire open enrollment period' do
      allow(hbx_enrollment).to receive(:open_enrollment_period_available?).and_return false
      allow(hbx_enrollment).to receive(:special_enrollment_period_available?).and_return false
      allow(hbx_enrollment).to receive(:new_hire_enrollment_period_available?).and_return true
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_enrolled', sponsored_benefit_package_id: current_benefit_package.id)
      expect(hbx_enrollment.can_make_changes?). to eq true
    end

    it 'should return false if enr is active and the employee is not in new hire open enrollment period' do
      allow(hbx_enrollment).to receive(:open_enrollment_period_available?).and_return false
      allow(hbx_enrollment).to receive(:special_enrollment_period_available?).and_return false
      allow(hbx_enrollment).to receive(:new_hire_enrollment_period_available?).and_return false
      hbx_enrollment.update_attributes(kind: 'employer_sponsored', aasm_state: 'coverage_enrolled', sponsored_benefit_package_id: current_benefit_package.id)
      expect(hbx_enrollment.can_make_changes?). to eq false
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

  let!(:ivl_enrollment_member)  { FactoryBot.create(:hbx_enrollment_member, is_subscriber: true,
                                  applicant_id: ivl_family.primary_applicant.id, hbx_enrollment: ivl_enrollment,
                                  eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record) }

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
      expect(HbxEnrollment.enrollments_for_display(ivl_family.id).map{|a|a['_id']}).to include (ivl_enrollment.id)
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


describe HbxEnrollment,"reinstate and change end date", type: :model, :dbclean => :around_each do
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
      let(:ivl_enrollment)    {
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
      }

      it "should re-instate enrollment" do
        ivl_enrollment.reinstate
        reinstated_enrollment = HbxEnrollment.where(family_id:ivl_family.id).detect{|e| e.coverage_selected?}

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
      let(:census_employee) { create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package, hired_on: hired_on, created_at: employee_created_at, updated_at: employee_updated_at) }
      let(:employee_role) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: census_employee.hired_on, census_employee_id: census_employee.id) }
      let(:enrollment_kind) { "open_enrollment" }
      let(:special_enrollment_period_id) { nil }
      let!(:shop_enrollment) { FactoryBot.create(:hbx_enrollment,
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
      }

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
          reinstated_enrollment = HbxEnrollment.where(family_id:shop_family.id).detect{|e| e.coverage_enrolled?}

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

      let(:ivl_enrollment)    {
        FactoryBot.create(:hbx_enrollment,
                           family: ivl_family,
                           household: ivl_family.latest_household,
                           coverage_kind: "health",
                           effective_on: TimeKeeper.date_of_record.last_year.beginning_of_year,
                           enrollment_kind: "open_enrollment",
                           kind: "individual",
                           aasm_state: "coverage_terminated",
                           terminated_on: TimeKeeper.date_of_record.last_year.end_of_year)
      }

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
      let(:census_employee) { create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package, hired_on: hired_on, created_at: employee_created_at, updated_at: employee_updated_at) }
      let(:employee_role) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: census_employee.hired_on, census_employee_id: census_employee.id) }
      let(:enrollment_kind) { "open_enrollment" }
      let(:special_enrollment_period_id) { nil }
      let!(:enrollment) { FactoryBot.create(:hbx_enrollment,
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
      }

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
          enrollment.employee_role.census_employee.update_attributes(aasm_state:'cobra_linked', cobra_begin_date: TimeKeeper.date_of_record)
        end

        it "should return false" do
          expect(enrollment.can_be_reinstated?).to be_falsey
        end
      end

      context "reinstating cobra enrollment for active employee" do

        before do
          enrollment.update_attributes(kind:'employer_sponsored_cobra', aasm_state: 'coverage_terminated', terminated_on: current_benefit_package.benefit_application.end_on - 1.month)
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
        ivl_enrollment2.update_attributes(effective_on: TimeKeeper.date_of_record.end_of_month + 1.day, aasm_state: "coverage_terminated",)
        ivl_enrollment2.reload
        expect(ivl_enrollment.has_active_term_or_expired_exists_for_reinstated_date?).to be_truthy
      end

      it "should return true if future active enrollment exists" do
        ivl_enrollment2.update_attributes(aasm_state: "coverage_selected", effective_on: TimeKeeper.date_of_record.beginning_of_month + 1.months)
        ivl_enrollment2.reload
        expect(ivl_enrollment.has_active_term_or_expired_exists_for_reinstated_date?).to be_truthy
      end

      it "should return false if no active enrollment exists for reinstated date" do
        ivl_enrollment2.update_attributes(effective_on: TimeKeeper.date_of_record.end_of_month + 1.day, aasm_state: "coverage_canceled",)
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
      let(:census_employee) { create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package, hired_on: hired_on, created_at: employee_created_at, updated_at: employee_updated_at) }
      let(:employee_role) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: census_employee.hired_on, census_employee_id: census_employee.id) }
      let(:enrollment_kind) { "open_enrollment" }
      let(:special_enrollment_period_id) { nil }
      let!(:enrollment) { FactoryBot.create(:hbx_enrollment,
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
      }
      let!(:enrollment2) { FactoryBot.create(:hbx_enrollment,
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

      }

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
        let(:census_employee2) { create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package, hired_on: hired_on, created_at: employee_created_at, updated_at: employee_updated_at) }
        let(:employee_role2) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: census_employee2.hired_on, census_employee_id: census_employee2.id) }
        let(:enrollment_kind) { "open_enrollment" }
        let(:special_enrollment_period_id) { nil }

        let!(:enrollment3) { FactoryBot.create(:hbx_enrollment,
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
                                               terminated_on: effective_on.end_of_month)}


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
    let!(:enrollment) {
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: "health",
                        kind: 'employer_sponsored',
                        effective_on: TimeKeeper.date_of_record.last_month.beginning_of_month,
                        terminated_on: original_termination_date,
                        aasm_state: 'coverage_termination_pending'
      )}
    let!(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }

    context "shop enrollment" do
      context "enrollment that already terminated with past date" do
        context "with new past or current termination date" do
          let(:terminated_date) { original_termination_date - 1.day }
          let(:original_termination_date) { TimeKeeper.date_of_record.beginning_of_month }

          it "should update enrollment with new end date and notify enrollment" do
            expect(enrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment", "is_trading_partner_publishable" => false})
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
            expect(enrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment", "is_trading_partner_publishable" => false})
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
            expect(enrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment", "is_trading_partner_publishable" => false})
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
            expect(enrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment", "is_trading_partner_publishable" => false})
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
    let!(:enrollment) {
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                         household: family.active_household,
                         coverage_kind: 'health',
                         kind: 'employer_sponsored',
                         effective_on: TimeKeeper.date_of_record.last_month.beginning_of_month,
                         terminated_on: TimeKeeper.date_of_record.end_of_month,
                         aasm_state: 'coverage_termination_pending'
      )}
    let!(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }

    context 'shop enrollment' do
      context 'enrollment that already terminated with past date' do
        context 'with new termination date == enrollment effective date' do

          before do
            enrollment.update_attributes(aasm_state:'coverage_terminated', terminated_on: TimeKeeper.date_of_record - 1.day)
            enrollment.reload
          end
          it 'should cancel enrollment' do
            expect(enrollment).to receive(:notify).with('acapi.info.events.hbx_enrollment.terminated', {:reply_to=>glue_event_queue_name, 'hbx_enrollment_id' => enrollment.hbx_id, 'enrollment_action_uri' => 'urn:openhbx:terms:v1:enrollment#terminate_enrollment', 'is_trading_partner_publishable' => false})
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
            expect(enrollment).to receive(:notify).with('acapi.info.events.hbx_enrollment.terminated', {:reply_to=>glue_event_queue_name, 'hbx_enrollment_id' => enrollment.hbx_id, 'enrollment_action_uri' => 'urn:openhbx:terms:v1:enrollment#terminate_enrollment', 'is_trading_partner_publishable' => false})
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
        enrollment.aasm_state= 'coverage_terminated'
        enrollment.save
      end

      context 'enrollment that already terminated with past date' do
        context 'with new termination date == enrollment effective date' do
          it 'should cancel enrollment' do
            enrollment.update_attributes(terminated_on: TimeKeeper.date_of_record - 1.day)
            expect(enrollment).to receive(:notify).with('acapi.info.events.hbx_enrollment.terminated', {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, 'enrollment_action_uri' => 'urn:openhbx:terms:v1:enrollment#terminate_enrollment', 'is_trading_partner_publishable' => false})
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
            expect(enrollment).to receive(:notify).with('acapi.info.events.hbx_enrollment.terminated', {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment", "is_trading_partner_publishable" => false})
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
