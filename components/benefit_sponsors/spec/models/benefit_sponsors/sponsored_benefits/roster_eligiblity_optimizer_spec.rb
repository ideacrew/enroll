require "rails_helper"

module BenefitSponsors
  RSpec.describe SponsoredBenefits::RosterEligibilityOptimizer do
    subject { ::BenefitSponsors::SponsoredBenefits::RosterEligibilityOptimizer.new }

    describe "given:
      - a sponsor which offers composite rating and contributions
      - with an 'employee_only' and 'family' groups (like CCA)
      - where all groups offered coverage by the sponsor" do

      let(:contribution_model) { double }
      let(:sponsor_contribution) do
        instance_double(
          "::BenefitSponsors::SponsoredBenefit::SponsorContribution",
          id: "a sponsor_conribution_id",
          contribution_levels: []
        )
      end

      describe "
        given:
          - a roster
          - with an employee
          - with a spouse
          - with a nibling
      " do

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

        let(:employee_member_id) { "some_employee_id" }
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

        let(:employee_dob) { Date.new(1990, 6, 1) }
        let(:roster_entry) do
          instance_double("::BenefitMarkets::SponsoredBenefits::BenefitRosterEntry",
            member_id: employee_member_id,
            dependents: [spouse, nibling],
            relationship: "self",
            is_disabled?: false,
            dob: employee_dob,
            roster_coverage: roster_coverage
          )
        end
        let(:employee_age) { 27 }

        before(:each) do
          allow(contribution_model).to receive(:map_relationship_for).with("self", employee_age, false).and_return("employee")
          allow(contribution_model).to receive(:map_relationship_for).with("spouse", spouse_age, false).and_return("spouse")
          allow(contribution_model).to receive(:map_relationship_for).with("nephew", nibling_age, false).and_return(nil)
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
  end
end
