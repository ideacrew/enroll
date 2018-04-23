require "rails_helper"

module BenefitSponsors
	RSpec.describe SponsoredBenefits::RosterEligibilityOptimizer do
		subject { ::BenefitSponsors::SponsoredBenefits::RosterEligibilityOptimizer.new }

		let(:employee_dob) { Date.new(1990, 6, 1) }
	  let(:employee_member_id) { "some_employee_id" }
		let(:roster_entry) do
			instance_double("::BenefitMarkets::SponsoredBenefits::BenefitRosterEntry",
											member_id: employee_member_id,
											dependents: roster_dependents,
											relationship: "self",
											is_disabled?: false,
											dob: employee_dob,
											roster_coverage: roster_coverage
										 )
		end
		let(:employee_age) { 27 }

		let(:product) { double(id: "some_product_id") }

		let(:coverage_start_date) { Date.new(2018, 1, 1) }

		let(:roster_coverage) do
			instance_double("::BenefitMarkets::SponsoredBenefits::RosterCoverage",
											rate_schedule_date: Date.new(2018, 1, 1),
											coverage_start_date: coverage_start_date,
											coverage_eligibility_dates: {},
											previous_eligibility_product: nil,
											product: product
										 )
		end

		describe "given:
			- a sponsor which offers composite rating and contributions
			- with an 'employee_only' and 'family' groups (like CCA)
			- where all groups offered coverage by the sponsor" do

			let(:contribution_model) { 
        instance_double(
          "::BenefitMarkets::ContributionModels::ContributionModel",
          contribution_units: [family_contribution_unit]
        )
      }

      let(:family_contribution_unit) do
        instance_double(
          "::BenefitMarkets::ContributionModels::ContributionUnit",
          id: "contribution_unit_id"
        )
      end

			let(:sponsor_contribution) do
				instance_double(
					"::BenefitSponsors::SponsoredBenefit::SponsorContribution",
					id: "a sponsor_conribution_id",
					contribution_levels: [family_contribution_level]
				)
			end

      let(:family_contribution_level) do
				instance_double(
					"::BenefitSponsors::SponsoredBenefits::ContributionLevel",
          contribution_unit_id: "contribution_unit_id",
          is_offered: true
        )
      end

			describe "
				given:
					- a roster
					- with an employee
					- with a spouse
					- with a nibling
			" do


				let(:spouse_member_id) { "some_spouse_id" }
				let(:nibling_member_id) { "some_nibbling_id" }
				let(:nibling_dob) { Date.new(2015, 1, 1) }
				let(:nibling) do
					instance_double(
						"::BenefitMarkets::SponsoredBenefits::RosterDependent",
						member_id: nibling_member_id,
						relationship: "nephew",
						is_disabled?: false,
						dob: nibling_dob
					)
				end

				let(:nibling_age) { 3 }

				let(:spouse_dob) { Date.new(1995, 9, 27) }
				let(:spouse) do
					instance_double(
						"::BenefitMarkets::SponsoredBenefits::RosterDependent",
						member_id: spouse_member_id,
						relationship: "spouse",
						is_disabled?: false,
						dob: spouse_dob
					)
				end
				let(:spouse_age) { 22 }

				let(:roster_dependents) { [spouse, nibling] }

				before(:each) do
					allow(contribution_model).to receive(:map_relationship_for).with("self", employee_age, false).and_return("employee")
					allow(contribution_model).to receive(:map_relationship_for).with("spouse", spouse_age, false).and_return("spouse")
					allow(contribution_model).to receive(:map_relationship_for).with("nephew", nibling_age, false).and_return(nil)
          allow(family_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1}).and_return(true)
				end

				it "removes the roster member with the unmappable relationship" do
					optimized_roster_entry = subject.calculate_optimal_group_for(
						contribution_model,
						roster_entry,
						sponsor_contribution
					)
					dependent_ids = optimized_roster_entry.dependents.map(&:member_id)
					expect(dependent_ids).not_to include(nibling_member_id)
				end
			end
		end

		describe "given:
			- a sponsor which offers composite rating and contributions
			- with an 'employee_only' and 'family' groups (like CCA)
			- where only 'employee_only' is offered by the sponsor" do

			let(:contribution_model) do
        instance_double(
          "::BenefitMarkets::ContributionModels::ContributionModel",
          contribution_units: [employee_contribution_unit, family_contribution_unit]
        )
      end

      let(:employee_contribution_unit) do
        instance_double(
          "::BenefitMarkets::ContributionModels::ContributionUnit",
          id: "employee_contribution_unit_id"
        )
      end

      let(:family_contribution_unit) do
        instance_double(
          "::BenefitMarkets::ContributionModels::ContributionUnit",
          id: "contribution_unit_id"
        )
      end

			let(:sponsor_contribution) do
				instance_double(
					"::BenefitSponsors::SponsoredBenefit::SponsorContribution",
					id: "a sponsor_conribution_id",
					contribution_levels: [employee_contribution_level, family_contribution_level]
				)
			end

      let(:employee_contribution_level) do
				instance_double(
					"::BenefitSponsors::SponsoredBenefits::ContributionLevel",
          contribution_unit_id: "employee_contribution_unit_id",
          is_offered: true
        )
      end

      let(:family_contribution_level) do
				instance_double(
					"::BenefitSponsors::SponsoredBenefits::ContributionLevel",
          contribution_unit_id: "contribution_unit_id",
          is_offered: false
        )
      end

			describe "
				given:
					- a roster
					- with an employee
					- with a spouse
					- with a nibling
			" do

				let(:spouse_member_id) { "some_spouse_id" }
				let(:spouse_dob) { Date.new(1995, 9, 27) }
				let(:spouse) do
					instance_double(
						"::BenefitMarkets::SponsoredBenefits::RosterDependent",
						member_id: spouse_member_id,
						relationship: "spouse",
						is_disabled?: false,
						dob: spouse_dob
					)
				end
				let(:spouse_age) { 22 }

				let(:roster_dependents) { [spouse] }

				before(:each) do
					allow(contribution_model).to receive(:map_relationship_for).with("self", employee_age, false).and_return("employee")
					allow(contribution_model).to receive(:map_relationship_for).with("spouse", spouse_age, false).and_return("spouse")
          allow(family_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1}).and_return(true)
          allow(family_contribution_unit).to receive(:match?).with({"employee" => 1}).and_return(false)
          allow(employee_contribution_unit).to receive(:match?).with({"employee" => 1, "spouse" => 1}).and_return(false)
          allow(employee_contribution_unit).to receive(:match?).with({"employee" => 1}).and_return(true)
				end

				it "removes the spouse" do
					optimized_roster_entry = subject.calculate_optimal_group_for(
						contribution_model,
						roster_entry,
						sponsor_contribution
					)
					dependent_ids = optimized_roster_entry.dependents.map(&:member_id)
					expect(dependent_ids).not_to include(spouse_member_id)
				end
			end
		end
	end
end
