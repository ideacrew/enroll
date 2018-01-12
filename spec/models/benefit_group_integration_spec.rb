require 'rails_helper'

describe BenefitGroup, dbclean: :after_each do
  describe "monthly_employer_contribution_amount" do
    context "with two employees expected to enroll" do
      let(:employer_profile) { FactoryGirl.create(:employer_profile, sic_code: '1111') }
      let!(:plan) { FactoryGirl.create(:plan)}
      let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile) }
      let!(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, effective_on_kind: "first_of_month", effective_on_offset: 30, plan_option_kind: 'sole_source', reference_plan_id: plan.id)}
      let!(:alt_benefit_group) { FactoryGirl.create(:benefit_group, effective_on_kind: "first_of_month", effective_on_offset: 30, plan_option_kind: 'sole_source', reference_plan_id: plan.id)}

      let!(:sic_factor) {
        SicCodeRatingFactorSet.create!({
          :carrier_profile_id => plan.carrier_profile_id,
          :active_year => plan.active_year,
          :default_factor_value => 1.0
        })
      }
      let!(:group_size_factors) {
        factor_entries = []
        [1,2,3,4].each do |n|
          factor_entries << build(:rating_factor_entry, factor_key: n, factor_value: n)
        end
        EmployerGroupSizeRatingFactorSet.create!({
          :carrier_profile_id => plan.carrier_profile_id,
          :active_year => plan.active_year,
          :default_factor_value => 1.0,
          :max_integer_factor_key => 4,
          :rating_factor_entries => factor_entries
        })
      }
      let!(:participation_rate_factor) {
        factor_entries = []
        factor_values = {
          0 => 5,
          25 => 4,
          50 => 3,
          75 => 2,
          99 => 1,
        }
        [0,25,50,75,99].each do |n|
          factor_entries << build(:rating_factor_entry, factor_key: n, factor_value: factor_values[n])
        end

        EmployerParticipationRateRatingFactorSet.create!({
          :carrier_profile_id => plan.carrier_profile_id,
          :active_year => plan.active_year,
          :default_factor_value => 1.0,
          rating_factor_entries: factor_entries
        })
      }

      let!(:census_employees) {
        [1,2].collect do
          FactoryGirl.create(:census_employee, employer_profile: employer_profile, benefit_group_assignments: [build(:benefit_group_assignment, benefit_group: benefit_group)])
        end
      }
      let!(:invalid_waived_employee) {
        FactoryGirl.create(:census_employee, employer_profile: employer_profile, expected_selection: 'will_not_participate', benefit_group_assignments: [build(:benefit_group_assignment, benefit_group: benefit_group)])
      }

      let!(:valid_waived_employee) {
        FactoryGirl.create(:census_employee, employer_profile: employer_profile, expected_selection: 'waive', benefit_group_assignments: [build(:benefit_group_assignment, benefit_group: benefit_group)])
      }

      before do
        allow(Caches::PlanDetails).to receive(:lookup_rate_with_area).and_return(100.00)
        benefit_group.estimate_composite_rates
      end

      ## Base Rate $100
      ## Sic Factor: 1.0
      ## Partipation Rate: 2 enroll + 1 waive / 4 total => 75 => 2.0
      ## Group Size: 2 enrolled  => 2.0
      ## Per employee total cost: $100 * 1.0 * 2.0 * 2.0 => $400
      ## Multplied by employer contribution factor 0.5 => $200
      ## Total cost: $200 * 2

      it "returns an accurate value" do
        expect(benefit_group.monthly_employer_contribution_amount).to eq(400)
      end

      context "with a terminated employee" do
        let!(:terminated_employee) {
          FactoryGirl.create(:census_employee, :termination_details, employer_profile: employer_profile, expected_selection: 'enroll', benefit_group_assignments: [build(:benefit_group_assignment, benefit_group: benefit_group)])
        }

        before do
          terminated_employee.aasm_state = "employment_terminated"
          terminated_employee.save!
        end

        it "does not include the terminated employee in calculations" do
          expect(benefit_group.monthly_employer_contribution_amount).to eq(400)
        end
      end

      context "with an employee in separate benefit group" do
        let!(:alternate_benefit_group_employee) {
          FactoryGirl.create(:census_employee, employer_profile: employer_profile, expected_selection: 'enroll')
        }
        before do
          alt_benefit_assignment = BenefitGroupAssignment.new_from_group_and_census_employee(alt_benefit_group, alternate_benefit_group_employee)
          alternate_benefit_group_employee.benefit_group_assignments = alt_benefit_assignment.to_a
          alternate_benefit_group_employee.save!
          alternate_benefit_group_employee.benefit_group_assignments.each do |bga|
            if bga.benefit_group.id == benefit_group.id
              bga.destroy!
            end
          end

          benefit_group.estimate_composite_rates
          alt_benefit_group.estimate_composite_rates
        end
        it "does not include the separate benefit group" do
          expect(benefit_group.monthly_employer_contribution_amount).to eq(400)
          expect(alt_benefit_group.monthly_employer_contribution_amount).to eq(50)
        end
      end

      context "for a benefit group that is not yet persisted" do
        let!(:edit_benefit_group) { build(:benefit_group, plan_year: plan_year) }

        before do
          edit_benefit_group.estimate_composite_rates
        end
        pending "should not include other employees" do
          expect(edit_benefit_group.monthly_employer_contribution_amount(plan)).to eq(400)
        end
      end
    end
  end
end
