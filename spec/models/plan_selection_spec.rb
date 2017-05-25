require 'rails_helper'

describe PlanSelection do

  subject { PlanSelection.new(hbx_enrollment, hbx_enrollment.plan) }

  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:person1) { FactoryGirl.create(:person, :with_consumer_role) }

  let(:family) {FactoryGirl.create(:family, :with_primary_family_member, :person => person)}
  let(:household) {FactoryGirl.create(:household, family: family)}

  let(:year){ TimeKeeper.date_of_record.year }
  let(:effective_on) { Date.new(year, 3, 1)}
  let(:previous_enrollment_status) { 'coverage_selected' }
  let(:terminated_on) { nil }
  let(:covered_individuals) { family.family_members }
  let(:newly_covered_individuals) { family.family_members }

  let(:plan) { 
    FactoryGirl.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'silver', active_year: year, hios_id: "11111111122301-01", csr_variant_id: "01")
  }

  let!(:previous_coverage){  
    FactoryGirl.create(:hbx_enrollment,:with_enrollment_members, 
     enrollment_members: covered_individuals,
     household: family.latest_household,
     coverage_kind: "health",
     effective_on: effective_on.beginning_of_year,
     enrollment_kind: "open_enrollment",
     kind: "individual",
     consumer_role: person.consumer_role,
     plan: plan,
     aasm_state: previous_enrollment_status,
     terminated_on: terminated_on
     ) }

  let!(:hbx_enrollment) {
    FactoryGirl.create(:hbx_enrollment,:with_enrollment_members, 
     enrollment_members: newly_covered_individuals,
     household: family.latest_household,
     coverage_kind: "health",
     effective_on: effective_on,
     enrollment_kind: "open_enrollment",
     kind: "individual",
     consumer_role: person.consumer_role,
     plan: plan
     )
  }

  before do
    TimeKeeper.set_date_of_record_unprotected!(effective_on) 
  end

  describe '.existing_enrollment_for_covered_individuals' do

    context 'when active coverage present' do 
      it 'should return active coverage' do 
        expect(subject.existing_enrollment_for_covered_individuals).to eq previous_coverage
      end
    end

    context 'when previous coverage is terminated' do 
      context 'and there is a gap in coverage' do
       let(:previous_enrollment_status) { 'coverage_terminated' }
       let(:terminated_on) { effective_on - 10.days }

        it 'should not return terminated enrollment' do 
          expect(subject.existing_enrollment_for_covered_individuals).to be_nil
        end 
      end

      context 'and no gap in coverage' do 
        let(:previous_enrollment_status) { 'coverage_terminated' }
        let(:terminated_on) { effective_on.prev_day }

        it 'should return terminated enrollment' do 
          expect(subject.existing_enrollment_for_covered_individuals).to eq previous_coverage
        end
      end
    end

    context 'when member not coverged before' do 
      let(:family_member) { FactoryGirl.create(:family_member, family: family, person: person1)}
      let(:covered_individuals) { family.family_members.select{|fm| fm != family_member} }
      let(:newly_covered_individuals) { family_member.to_a }

      it 'should return nothing' do 
        expect(subject.existing_enrollment_for_covered_individuals).to be_nil
      end
    end
  end

  describe '.set_enrollment_member_coverage_start_dates' do 
    context 'when a new enrollment has a previous enrollment' do 
      def hash_key_creator(hbx_enrollment_member)
        hbx_enrollment_member.person.hbx_id
      end
      it 'should set eligibility dates to that of the previous enrollment' do
        subject.set_enrollment_member_coverage_start_dates
        previous_eligibility_dates = Hash[previous_coverage.hbx_enrollment_members.collect {|hbx_em| [hash_key_creator(hbx_em), hbx_em.coverage_start_on]} ]
        new_eligibility_dates = Hash[hbx_enrollment.hbx_enrollment_members.collect {|hbx_em| [hash_key_creator(hbx_em), hbx_em.coverage_start_on]} ]
        new_eligibility_dates.each do |hbx_id,date|
          expect(previous_eligibility_dates[hbx_id]).to eq(date)
        end
      end
    end
  end
end

describe PlanSelection,  '.previous_active_coverages' do
  subject { PlanSelection.new(hbx_enrollment, hbx_enrollment.plan) }

  let(:calender_year) { TimeKeeper.date_of_record.year }

  let!(:employer_profile) { create(:employer_with_renewing_planyear, renewal_plan_year_state: 'active', start_on: Date.new(calender_year,3,1)) }
  let(:benefit_group) { employer_profile.plan_years.where(:start_on => Date.new(calender_year,3,1)).first.benefit_groups.first }
  let(:prev_benefit_group) { employer_profile.plan_years.where(:start_on => Date.new(calender_year,3,1).prev_year).first.benefit_groups.first }

  let!(:census_employees){
    FactoryGirl.create :census_employee, :owner, employer_profile: employer_profile
    employee = FactoryGirl.create :census_employee, employer_profile: employer_profile
    employer_profile.plan_years.each do |py|
      employee.add_benefit_group_assignment py.benefit_groups.first, py.benefit_groups.first.start_on
      employee.add_benefit_group_assignment py.benefit_groups.first, py.benefit_groups.first.start_on
    end
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

  let(:person) { family.primary_applicant.person }
  let(:effective_on) { benefit_group.start_on + 3.months }
  let(:prev_effective_on) { benefit_group.start_on }
  let(:prev_status) { 'coverage_selected' }
  let(:prev_terminated_on) { nil }

  let!(:hbx_enrollment) {
    FactoryGirl.create(:hbx_enrollment,
     household: family.active_household,
     coverage_kind: "health",
     effective_on: effective_on,
     enrollment_kind: "open_enrollment",
     kind: "employer_sponsored",
     benefit_group_id: benefit_group.id,
     employee_role_id: person.active_employee_roles.first.id,
     benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
     plan_id: plan.id,
     aasm_state: 'shopping'
     )
  }

  let!(:past_hbx_enrollment) {
    FactoryGirl.create(:hbx_enrollment,
     household: family.active_household,
     coverage_kind: "health",
     effective_on: prev_effective_on,
     enrollment_kind: "open_enrollment",
     kind: "employer_sponsored",
     benefit_group_id: benefit_group.id,
     employee_role_id: person.active_employee_roles.first.id,
     benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
     plan_id: plan.id,
     terminated_on: prev_terminated_on,
     aasm_state: prev_status
     )
  }

  before do
    TimeKeeper.set_date_of_record_unprotected!(effective_on - 17.days) 
  end

  context 'under employer sponsored' do 

    context 'when terminated shop enrollment exists with a gap in coverage' do
      let(:prev_terminated_on) { effective_on.prev_month }
      let(:prev_status) { 'coverage_terminated' }

      it 'should not select terminated enrollment' do 
        expect(subject.previous_active_coverages).to be_empty
      end
    end

    context 'when a terminated enrollment present without coverage gap' do
      let(:prev_terminated_on) { effective_on.prev_day }
      let(:prev_status) { 'coverage_terminated' }

      it 'should select terminated enrollment' do
        expect(subject.previous_active_coverages.first).to eq(past_hbx_enrollment)
      end
    end

    context 'when an enrollment present with same effective date or future effective date' do
      let(:prev_effective_on) { effective_on }

      it 'should not select the enrollment' do
        expect(subject.previous_active_coverages).to be_empty
      end
    end

    context 'when multiple past enrollments present' do
      let!(:past_hbx_enrollment2) {
        FactoryGirl.create(:hbx_enrollment,
         household: family.active_household,
         coverage_kind: "health",
         effective_on: prev_effective_on.next_month,
         enrollment_kind: "open_enrollment",
         kind: "employer_sponsored",
         benefit_group_id: benefit_group.id,
         employee_role_id: person.active_employee_roles.first.id,
         benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
         plan_id: plan.id,
         aasm_state: prev_status
         )
      }

      it 'should select the most recent enrollment' do
        expect(subject.previous_active_coverages.first).to eq(past_hbx_enrollment2)
      end
    end

    context 'when a past waiver enrollment present' do
      let(:prev_status) { 'inactive' }

      it 'should not select the enrollment' do
        expect(subject.previous_active_coverages).to be_empty
      end
    end

    context 'when a past canceled enrollment present' do
      let(:prev_status) { 'coverage_canceled' }

      it 'should not select the enrollment' do
        expect(subject.previous_active_coverages).to be_empty
      end
    end

    context 'different plan year enrollment present' do 
      let!(:past_hbx_enrollment2) {
        FactoryGirl.create(:hbx_enrollment,
         household: family.active_household,
         coverage_kind: "health",
         effective_on: prev_benefit_group.start_on,
         enrollment_kind: "open_enrollment",
         kind: "employer_sponsored",
         benefit_group_id: prev_benefit_group.id,
         employee_role_id: person.active_employee_roles.first.id,
         benefit_group_assignment_id: ce.benefit_group_assignments.first.id,
         plan_id: plan.id,
         aasm_state: prev_status
         )
      }

      context 'when multiple enrollments present under different plan years' do 
        it 'should select same plan year enrollment' do
          expect(subject.previous_active_coverages.size).to eq 1
          expect(subject.previous_active_coverages.first).to eq past_hbx_enrollment 
        end
      end

      context 'when an enrollment belongs to different plan year' do
        it 'should not select the enrollment' do
          past_hbx_enrollment.delete
          expect(subject.previous_active_coverages.empty?).to be_truthy
        end 
      end
    end
  end
end
