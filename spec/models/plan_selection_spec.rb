require 'rails_helper'

describe PlanSelection do

  subject { PlanSelection.new(hbx_enrollment, hbx_enrollment.plan) }

  let(:person) do
    person = FactoryGirl.create(:person, :with_active_consumer_role, :with_consumer_role)
    person.consumer_role.aasm_state = "verification_outstanding"
    person
  end
  let(:person1) do
    person = FactoryGirl.create(:person, :with_active_consumer_role, :with_consumer_role)
    person.consumer_role.aasm_state = "verification_outstanding"
    person
  end

  let(:family) {FactoryGirl.create(:family, :with_primary_family_member, :person => person)}
  let(:household) {FactoryGirl.create(:household, family: family)}

  let(:year){ TimeKeeper.date_of_record.year }
  let(:effective_on) { Date.new(year, 3, 1)}
  let(:previous_enrollment_status) { 'coverage_selected' }
  let(:terminated_on) { nil }
  let(:covered_individuals) { family.family_members }
  let(:newly_covered_individuals) { family.family_members }
  let(:person_shop) { FactoryGirl.create(:person, :with_family)}
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month }
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:qualifying_life_event_kind) { FactoryGirl.create(:qualifying_life_event_kind)}
  let(:special_enrollment_period) {
        special_enrollment = person_shop.primary_family.special_enrollment_periods.build({
                                                                            # qle_on: qle_date,
                                                                            effective_on_kind: "first_of_month",
        })
        special_enrollment.qualifying_life_event_kind = qualifying_life_event_kind
        special_enrollment.start_on = TimeKeeper.date_of_record.prev_day
        special_enrollment.end_on = TimeKeeper.date_of_record + 30.days
        special_enrollment.save
        special_enrollment
      }
  let(:employee_role) {FactoryGirl.create(:employee_role, person: person_shop, census_employee: census_employee, employer_profile: employer_profile)}
  let!(:plan_year) {FactoryGirl.create(:plan_year, employer_profile: employer_profile, aasm_state: 'termination_pending', start_on: start_on, end_on: TimeKeeper.date_of_record.next_month.end_of_month)}
  let!(:benefit_group) {FactoryGirl.create(:benefit_group, plan_year: plan_year)}
  let(:benefit_group_assignment1) {FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group, end_on: plan_year.end_on)}
  let!(:census_employee) { FactoryGirl.create(:census_employee, benefit_group_assignments: [benefit_group_assignment1],employer_profile_id: employer_profile.id) }
  let(:shop_household) { FactoryGirl.create(:household, family: person_shop.primary_family)}
  let!(:hbx_enrollment_shop) { FactoryGirl.create(:hbx_enrollment,
                                                  household: person_shop.primary_family.households.first,
                                                  special_enrollment_period_id: special_enrollment_period.id,
                                                  benefit_group_id: benefit_group.id,
                                                  aasm_state: "shopping",
                                                  benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
                                                  employee_role_id: employee_role.id)
  }

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

  describe '.existing_enrollment_for_covered_individuals' do

    before do
      TimeKeeper.set_date_of_record_unprotected!(effective_on)
    end

    after do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

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

    before do
      TimeKeeper.set_date_of_record_unprotected!(effective_on)
    end

    after do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

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
  
  describe ".select_plan_and_deactivate_other_enrollments" do

    context 'hbx_enrollment aasm state check' do

      before do
        TimeKeeper.set_date_of_record_unprotected!(effective_on)
      end

      after do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end

      it 'should set is_any_enrollment_member_outstanding to true if any verification outstanding people' do
        subject.hbx_enrollment.hbx_enrollment_members.flat_map(&:person).flat_map(&:consumer_role).first.update_attribute("aasm_state","verification_outstanding")
        subject.hbx_enrollment.update_attributes(aasm_state: "shopping")
        subject.select_plan_and_deactivate_other_enrollments(nil,"individual")
        expect(subject.hbx_enrollment.aasm_state).to eq("coverage_selected")
        expect(subject.hbx_enrollment.is_any_enrollment_member_outstanding).to eq true
      end

      it 'should set is_any_enrollment_member_outstanding to false if no verification outstanding people' do
        subject.hbx_enrollment.hbx_enrollment_members.flat_map(&:person).flat_map(&:consumer_role).first.update_attribute("aasm_state","verified")
        subject.hbx_enrollment.update_attributes(aasm_state: "shopping")
        subject.select_plan_and_deactivate_other_enrollments(nil,"individual")
        expect(subject.hbx_enrollment.aasm_state).to eq("coverage_selected")
        expect(subject.hbx_enrollment.is_any_enrollment_member_outstanding).to eq false
      end
    end

    context "when plan year is in termination pending" do
      subject { PlanSelection.new(hbx_enrollment_shop, hbx_enrollment_shop.plan) }
      it "enrollment should be moved to termination pending" do
        allow(family).to receive(:earliest_effective_shop_sep).and_return special_enrollment_period
        subject.select_plan_and_deactivate_other_enrollments(nil,"shop")
        subject.hbx_enrollment.reload
        expect(subject.hbx_enrollment.aasm_state).to eq("coverage_termination_pending")
      end
    end

  end
end