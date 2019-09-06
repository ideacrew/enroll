require "rails_helper"

module BenefitSponsors
  RSpec.describe ContributionCalculators::TieredPercentContributionCalculator, :dbclean => :after_each do
    let(:contribution_calculator) do
      ::BenefitSponsors::ContributionCalculators::TieredPercentContributionCalculator.new
    end

    let(:contribution_model) do
      instance_double(
        ::BenefitMarkets::ContributionModels::ContributionModel,
        :contribution_units => contribution_units
      )
    end

    let(:product) { double }

    let(:benefit_roster) do
      benefit_roster_entries
    end

    describe "given:
    - a tiered pricing model
    - with an 'employee_only' group
    - with an 'employee_and_spouse' group
    - with an 'employee_and_dependents' group
    - with a 'family' group" do

      let(:contribution_units) do
        [
          employee_only_contribution_unit,
          employee_and_spouse_contribution_unit,
          employee_and_dependents_contribution_unit,
          family_contribution_unit
        ]
      end

      let(:employee_only_contribution_unit) do
        instance_double(
          ::BenefitMarkets::ContributionModels::FixedPercentContributionUnit,
          name: "employee_only",
          id: "employee_only_cu_id"
        )
      end

      let(:employee_and_spouse_contribution_unit) do
        instance_double(
          ::BenefitMarkets::ContributionModels::FixedPercentContributionUnit,
          name: "employee_and_spouse",
          id: "employee_and_spouse_cu_id"
        )
      end

      let(:employee_and_dependents_contribution_unit) do
        instance_double(
          ::BenefitMarkets::ContributionModels::FixedPercentContributionUnit,
          name: "employee_and_dependents",
          id: "employee_and_dependents_cu_id"
        )
      end

      let(:family_contribution_unit) do
        instance_double(
          ::BenefitMarkets::ContributionModels::FixedPercentContributionUnit,
          name: "family",
          id: "family_cu_id"
        )
      end

      describe "with a pricing determination and one family that has:
        - an employee
        - a spouse
        - a child
      " do

        let(:employee_dob) { Date.new(1990, 6, 1) }
        let(:employee_member_id) { "some_employee_id" }

        let(:employee) do
          instance_double(
            "::BenefitMarkets::SponsoredBenefits::RosterMember",
            member_id: employee_member_id,
            relationship: "self",
            is_disabled?: false,
            is_primary_member?: true,
            dob: employee_dob
          )
        end
        let(:employee_enrollment) do
          BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: employee_member_id,
            product_price: primary_price 
          )
        end
        let(:employee_age) { 27 }

        let(:spouse_member_id) { "some_spouse_id" }
        let(:spouse_dob) { Date.new(1995, 9, 27) }
        let(:spouse) do
          instance_double(
            "::BenefitMarkets::SponsoredBenefits::RosterMember",
            member_id: spouse_member_id,
            relationship: "spouse",
            is_disabled?: false,
            dob: spouse_dob,
            is_primary_member?: false
          )
        end
        let(:spouse_age) { 22 }
        let(:spouse_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: spouse_member_id,
            product_price: dependent_price
          )
        end

        let(:child_member_id) { "some_child1_member_id" }
        let(:child_dob) { Date.new(2015, 1, 1) }
        let(:child) do
          instance_double(
            "::BenefitMarkets::SponsoredBenefits::RosterMember",
            member_id: child_member_id,
            relationship: "child",
            is_disabled?: false,
            dob: child_dob,
            is_primary_member?: false
          )
        end
        let(:child_enrollment) do
          ::BenefitSponsors::Enrollments::MemberEnrollment.new(
            member_id: child_member_id,
            product_price: dependent_price
          )
        end
        let(:child_age) { 3 }

        let(:coverage_start_date) { Date.new(2018, 1, 1) }
        let(:rate_schedule_date) { Date.new(2018, 1, 1) }

        let(:family_group_enrollment) do
          BenefitSponsors::Enrollments::GroupEnrollment.new(
            member_enrollments: [employee_enrollment, spouse_enrollment, child_enrollment],
            rate_schedule_date: rate_schedule_date,
            coverage_start_on: coverage_start_date,
            previous_product: nil,
            product: product,
            rating_area: "MA1",
            product_cost_total: family_price
          )
        end

        let(:family_roster_entry) do
          ::BenefitSponsors::Members::MemberGroup.new(
            [employee, spouse, child],
            group_enrollment: family_group_enrollment
          )
        end

        let(:family_price) { 320.00 }
        let(:primary_price) { 106.68 }
        let(:dependent_price) { 106.66 }

        let(:total_contribution) { 80.00 }

        let(:family_contribution_level) do
          instance_double(
            ::BenefitSponsors::SponsoredBenefits::ContributionLevel,
            contribution_unit_id: "family_cu_id",
            contribution_factor: 0.25
          )
        end

        let(:sponsor_contribution) do
          instance_double(
            ::BenefitSponsors::SponsoredBenefits::FixedPercentSponsorContribution,
            contribution_levels: [family_contribution_level],
            id: "some cacheable id"
          )
        end

        before(:each) do
          allow(contribution_model).to receive(:map_relationship_for).with("self", employee_age, false).and_return("employee")
          allow(contribution_model).to receive(:map_relationship_for).with("spouse", spouse_age, false).and_return("spouse")
          allow(contribution_model).to receive(:map_relationship_for).with("child", child_age, false).and_return("dependent")
          allow(employee_only_contribution_unit).to receive(:match?).with({"dependent"=>1, "employee"=>1, "spouse"=>1}).and_return(false)
          allow(employee_and_spouse_contribution_unit).to receive(:match?).with({"dependent"=>1, "employee"=>1, "spouse"=>1}).and_return(false)
          allow(employee_and_dependents_contribution_unit).to receive(:match?).with({"dependent"=>1, "employee"=>1, "spouse"=>1}).and_return(false)
          allow(family_contribution_unit).to receive(:match?).with({"dependent"=>1, "employee"=>1, "spouse"=>1}).and_return(true)
        end

        it "calculates the total contribution" do
          calculation_result = contribution_calculator.calculate_contribution_for(
            contribution_model,
            family_roster_entry,
            sponsor_contribution
          )
          expect(calculation_result.group_enrollment.sponsor_contribution_total).to eq(total_contribution)
        end

        it "calculates the member contributions" do
          calculation_result = contribution_calculator.calculate_contribution_for(
            contribution_model,
            family_roster_entry,
            sponsor_contribution
          )
          member_total = calculation_result.group_enrollment.member_enrollments.inject(BigDecimal.new("0.00")) do |acc, m_en|
            BigDecimal.new((acc + m_en.sponsor_contribution).to_s).round(2)
          end
          expect(member_total).to eq(total_contribution)
        end

        context 'for invalid relationships' do
          let(:parent_member_id) { "some_parent1_member_id" }
          let(:parent_dob) { Date.new(2015, 1, 1) }
          let(:parent) do
            instance_double(
              "::BenefitMarkets::SponsoredBenefits::RosterMember",
              member_id: parent_member_id,
              relationship: "parent",
              is_disabled?: false,
              dob: parent_dob,
              is_primary_member?: false
            )
          end
          let(:parent_enrollment) do
            ::BenefitSponsors::Enrollments::MemberEnrollment.new(
              member_id: parent_member_id,
              product_price: dependent_price
            )
          end
          let(:parent_age) { 3 }

          let(:invalid_family_group_enrollment) do
            BenefitSponsors::Enrollments::GroupEnrollment.new(
              member_enrollments: [employee_enrollment, spouse_enrollment, parent_enrollment],
              rate_schedule_date: rate_schedule_date,
              coverage_start_on: coverage_start_date,
              previous_product: nil,
              product: product,
              rating_area: "MA1",
              product_cost_total: family_price
            )
          end

          let(:invalid_family_roster_entry) do
            ::BenefitSponsors::Members::MemberGroup.new(
              [employee, spouse, parent],
              group_enrollment: invalid_family_group_enrollment
            )
          end

          let(:calculator_state) do
            roster_coverage = invalid_family_roster_entry.group_enrollment
            member_pricing = {}
            roster_coverage.member_enrollments.each do |m_en|
              member_pricing[m_en.member_id] = m_en.product_price
            end
            level_map = contribution_calculator.send(:level_map_for, sponsor_contribution)
            coverage_eligibility_dates = {}
            roster_coverage.member_enrollments.each do |m_en|
              coverage_eligibility_dates[m_en.member_id] = m_en.coverage_eligibility_on
            end
            cal_klass = BenefitSponsors::ContributionCalculators::TieredPercentContributionCalculator::CalculatorState
            cal_klass.new(contribution_model,
                          level_map,
                          member_pricing,
                          coverage_eligibility_dates,
                          coverage_start_date,
                          roster_coverage,
                          roster_coverage.sponsor_contribution_prohibited)
          end

          before :each do
            allow(contribution_model).to receive(:map_relationship_for).with("parent", parent_age, false).and_return(nil)
          end

          it 'should raise UnmatchedRelationshipError' do
            error_klass = ::BenefitSponsors::ContributionCalculators::UnmatchedRelationshipError
            expect{calculator_state.add(parent)}.to raise_error(error_klass)
          end

          it 'calculates the total contribution' do
            calculation_result = contribution_calculator.calculate_contribution_for(
              contribution_model,
              invalid_family_roster_entry,
              sponsor_contribution
            )
            expect(calculation_result.group_enrollment.sponsor_contribution_total).to eq(0.00)
          end

          it 'calculates the member contributions' do
            calculation_result = contribution_calculator.calculate_contribution_for(
              contribution_model,
              invalid_family_roster_entry,
              sponsor_contribution
            )
            member_total = calculation_result.group_enrollment.member_enrollments.inject(BigDecimal("0.00")) do |acc, m_en|
              BigDecimal((acc + m_en.sponsor_contribution).to_s).round(2)
            end
            expect(member_total).to eq(0.00)
          end
        end
      end
    end
  end
end
