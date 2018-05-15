require 'rails_helper'

RSpec.describe Enrollments::Replicator::Reinstatement, :type => :model do

  describe 'initial employer' do 
    let(:current_date) { Date.new(TimeKeeper.date_of_record.year, 6, 1) }
    let(:effective_on_date)         { Date.new(TimeKeeper.date_of_record.year, 3, 1) }
    let(:terminated_on_date)        {effective_on_date + 10.days}

    let!(:employer_profile) { create(:employer_with_planyear, plan_year_state: 'active', start_on: effective_on_date)}
    let(:benefit_group) { employer_profile.published_plan_year.benefit_groups.first}

    let!(:census_employees){
      FactoryGirl.create :census_employee, :owner, employer_profile: employer_profile
      employee = FactoryGirl.create :census_employee, employer_profile: employer_profile
      employee.add_benefit_group_assignment benefit_group, benefit_group.start_on
    }

    let!(:plan) {
      FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: benefit_group.start_on.year, hios_id: "11111111122302-01", csr_variant_id: "01")
    }

    let(:ce) { employer_profile.census_employees.non_business_owner.first }

    let!(:family) {
      person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
      ce.update_attributes({employee_role: employee_role})
      Family.find_or_build_from_employee_role(employee_role)
    }

    let(:covered_individuals) { family.family_members }
    let(:person) { family.primary_applicant.person }

    let!(:enrollment) {
      FactoryGirl.create(:hbx_enrollment, :with_enrollment_members,
       enrollment_members: covered_individuals,
       household: family.active_household,
       coverage_kind: "health",
       effective_on: effective_on_date,
       enrollment_kind: "open_enrollment",
       kind: "employer_sponsored",
       benefit_group_id: benefit_group.id,
       employee_role_id: person.active_employee_roles.first.id,
       benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
       plan_id: plan.id
       )
    }

    before do
      TimeKeeper.set_date_of_record_unprotected!(current_date)
      ce.terminate_employment(effective_on_date + 45.days)
      enrollment.reload
      ce.reload
    end

    context 'when enrollment reinstated' do

      let(:reinstated_enrollment) {
        Enrollments::Replicator::EmployerSponsored.new(enrollment, enrollment.terminated_on.next_day).build
      }

      it "should build reinstated enrollment" do
        expect(reinstated_enrollment.kind).to eq enrollment.kind
        expect(reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
        expect(reinstated_enrollment.plan_id).to eq enrollment.plan_id
      end

      it 'should build a continuous coverage' do
        expect(reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
      end

      it 'should give same member coverage begin date as base enrollment to calculate premious correctly' do
        enrollment_member = reinstated_enrollment.hbx_enrollment_members.first
        expect(enrollment_member.coverage_start_on).to eq enrollment.effective_on
        expect(enrollment_member.eligibility_date).to eq reinstated_enrollment.effective_on
        expect(reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
      end   
    end
  end

  describe "renewing employer" do
    context "enrollment reinstate effective date" do

      let(:plan_year_start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month } 
      let(:plan_metal_level) { 'gold' }
      let(:coverage_kind) { 'health' }

      let!(:renewal_plan) { 
        FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: plan_metal_level, active_year: plan_year_start_on.year, hios_id: "11111111122302-01", csr_variant_id: "01", coverage_kind: coverage_kind)
      }

      let!(:plan) {
        FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: plan_metal_level, active_year: plan_year_start_on.year - 1, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id, coverage_kind: coverage_kind)
      }

      let(:renewing_employer) {
        FactoryGirl.create(:employer_with_renewing_planyear, start_on: plan_year_start_on,
          renewal_plan_year_state: 'renewing_enrolling',
          reference_plan_id: plan.id,
          renewal_reference_plan_id: renewal_plan.id
          )
      }

      let(:renewing_employees) {
        FactoryGirl.create_list(:census_employee_with_active_and_renewal_assignment, 4, hired_on: (TimeKeeper.date_of_record - 2.years), employer_profile: renewing_employer, 
          benefit_group: renewing_employer.active_plan_year.benefit_groups.first, 
          renewal_benefit_group: renewing_employer.renewing_plan_year.benefit_groups.first)
      }

      let(:generate_renewal) {
        factory = Factories::FamilyEnrollmentRenewalFactory.new
        factory.family = current_employee.person.primary_family.reload
        factory.census_employee = current_employee.census_employee.reload
        factory.employer = renewing_employer.reload
        factory.renewing_plan_year = renewing_employer.renewing_plan_year.reload
        factory.renew
      }

      let(:current_family) { current_employee.person.primary_family }

      let(:ce) { renewing_employees[0] }

      let(:employee_A) {
        create_person(ce, renewing_employer)
      }

      let!(:enrollment) {
        create_enrollment(family: employee_A.person.primary_family, benefit_group_assignment: employee_A.census_employee.active_benefit_group_assignment, employee_role: employee_A, submitted_at: plan_year_start_on.prev_year, coverage_kind: coverage_kind)
      }

      let(:current_employee) {
        employee_A
      }

      def create_person(ce, employer_profile)
        person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
        employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
        ce.update_attributes({employee_role: employee_role})
        Family.find_or_build_from_employee_role(employee_role)
        employee_role
      end

      def create_enrollment(family: nil, benefit_group_assignment: nil, employee_role: nil, status: 'coverage_selected', submitted_at: nil, enrollment_kind: 'open_enrollment', effective_date: nil, coverage_kind: 'health')
        benefit_group = benefit_group_assignment.benefit_group
        FactoryGirl.create(:hbx_enrollment,:with_enrollment_members,
          enrollment_members: [family.primary_applicant],
          household: family.active_household,
          coverage_kind: coverage_kind,
          effective_on: plan_year_start_on.prev_year,
          enrollment_kind: enrollment_kind,
          kind: "employer_sponsored",
          submitted_at: submitted_at,
          benefit_group_id: benefit_group.id,
          employee_role_id: employee_role.id,
          benefit_group_assignment_id: benefit_group_assignment.id,
          plan_id: benefit_group.reference_plan.id,
          aasm_state: status
          )
      end

      context "prior to renewing plan year begin date" do 
        let(:reinstate_effective_date) { plan_year_start_on.prev_month }

        let(:reinstated_enrollment) {
          enrollment.reinstate(edi: false)
        }

        before do
          ce.terminate_employment(reinstate_effective_date.prev_day)
          enrollment.reload
          ce.reload
        end

        it "should build reinstated enrollment" do
          expect(reinstated_enrollment.kind).to eq enrollment.kind
          expect(reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
          expect(reinstated_enrollment.plan_id).to eq enrollment.plan_id
        end

        it 'should build a continuous coverage' do
          expect(reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
        end

        it 'should give same member coverage begin date as base enrollment to calculate premious correctly' do
          enrollment_member = reinstated_enrollment.hbx_enrollment_members.first
          expect(enrollment_member.coverage_start_on).to eq enrollment.effective_on
          expect(enrollment_member.eligibility_date).to eq reinstated_enrollment.effective_on
          expect(reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
        end

        it "should generate passive renewal" do 
          reinstated_enrollment
          enrollment = current_family.active_household.hbx_enrollments.where({
            :effective_on => plan_year_start_on,
            :aasm_state.ne => 'coverage_canceled'
            }).first

          expect(enrollment.present?).to be_truthy
          expect(enrollment.benefit_group.plan_year).to eq renewing_employer.renewing_plan_year
        end
      end

      context "same as renewing plan year begin date" do
        let(:reinstate_effective_date) { plan_year_start_on }

        context "when plan year is renewing" do
          let(:reinstated_enrollment) { enrollment.reinstate(edi: false) }

          before do
            enrollment.terminate_coverage!(reinstate_effective_date.prev_day)
            enrollment.reload
            ce.reload
          end

          it "should build reinstated enrollment" do
            expect(reinstated_enrollment.kind).to eq enrollment.kind
            expect(reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
          end

          it "should generate reinstated enrollment with next plan year" do
            expect(reinstated_enrollment.effective_on).to eq plan_year_start_on
            expect(reinstated_enrollment.benefit_group.plan_year).to eq renewing_employer.renewing_plan_year
            expect(reinstated_enrollment.plan_id).to eq renewal_plan.id
          end

          it 'should build a continuous coverage' do
            expect(reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
          end

          it 'should give same member coverage begin date as base enrollment to calculate premious correctly' do
            enrollment_member = reinstated_enrollment.hbx_enrollment_members.first
            expect(enrollment_member.coverage_start_on).to eq reinstated_enrollment.effective_on
            expect(enrollment_member.eligibility_date).to eq reinstated_enrollment.effective_on
            expect(reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
          end

          it "should not generate any other passive renewal" do
            reinstated_enrollment
            enrollment = current_family.active_household.hbx_enrollments.where({
              :effective_on => plan_year_start_on,
              :aasm_state.ne => 'coverage_canceled'
              }).detect{|en| en != reinstated_enrollment}
            expect(enrollment).to be_nil
          end
        end

        context "when renewal plan year is already active" do 
          let(:reinstated_enrollment) { enrollment.reinstate(edi: false) }

          before do
            TimeKeeper.set_date_of_record_unprotected!(plan_year_start_on + 5.days)
            ce.terminate_employment(reinstate_effective_date.prev_day)
            enrollment.reload
            ce.reload
            renewing_employer.active_plan_year.update(aasm_state: 'expired')
            renewing_employer.renewing_plan_year.update(aasm_state: 'active')
            renewing_employer.reload
          end

          it "should build reinstated enrollment" do
            expect(reinstated_enrollment.kind).to eq enrollment.kind
            expect(reinstated_enrollment.coverage_kind).to eq enrollment.coverage_kind
          end

          it "should generate reinstated enrollment with next plan year" do
            expect(reinstated_enrollment.effective_on).to eq plan_year_start_on
            expect(reinstated_enrollment.benefit_group.plan_year).to eq renewing_employer.published_plan_year
            expect(reinstated_enrollment.plan_id).to eq renewal_plan.id
          end

          it 'should build a continuous coverage' do
            expect(reinstated_enrollment.effective_on).to eq enrollment.terminated_on.next_day
          end

          it 'should give same member coverage begin date as base enrollment to calculate premious correctly' do
            enrollment_member = reinstated_enrollment.hbx_enrollment_members.first
            expect(enrollment_member.coverage_start_on).to eq reinstated_enrollment.effective_on
            expect(enrollment_member.eligibility_date).to eq reinstated_enrollment.effective_on
            expect(reinstated_enrollment.hbx_enrollment_members.size).to eq enrollment.hbx_enrollment_members.size
          end

          it "should not generate any other passive renewal" do
            reinstated_enrollment
            enrollment = current_family.active_household.hbx_enrollments.where({
              :effective_on => plan_year_start_on,
              :aasm_state.ne => 'coverage_canceled'
              }).detect{|en| en != reinstated_enrollment}
            expect(enrollment).to be_nil
          end
        end 
      end
    end
  end
end
