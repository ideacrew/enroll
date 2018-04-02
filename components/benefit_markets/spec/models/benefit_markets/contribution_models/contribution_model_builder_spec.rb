require 'rails_helper'

module BenefitMarkets
  class MockContributionUnitValue
    attr_accessor :contribution_unit_id
    attr_accessor :contribution_cap
    attr_accessor :contribution_factor

    def initialize(opts = {})
      opts.each_key do |k|
        self.send("#{k}=",opts[k])
      end
    end
  end

  RSpec.describe ContributionModels::ContributionModelBuilder do
    describe "given a contribution model for Fehb" do
      let(:contribution_unit) do
        ContributionModels::PercentWithCapContributionUnit.new(
          name: "employee_only",
          display_name: "Employee Only",
          member_relationship_maps: [member_relationship_map],
          default_contribution_factor: 0.75,
          default_contribution_cap: 500.00,
          order: 0
        )
      end

      let(:member_relationship_map) do
        ContributionModels::MemberRelationshipMap.new(
          relationship_name: "employee",
          operator: :==,
          count: 1
        )
      end

      let(:member_relationship) do
        ContributionModels::MemberRelationship.new(
          relationship_name: "employee",
          relationship_kinds: ["self"]
        )
      end
      let(:contribution_units) { [contribution_unit] }
      let(:member_relationships) { [member_relationship] }

      let(:contribution_model) do
        ContributionModels::FehbContributionModel.new(
          :contribution_level_kind => "::BenefitMarkets::MockContributionUnitValue",
          :contribution_units => contribution_units,
          :member_relationships => member_relationships,
          :name => "Federal Heath Benefits"
        )
      end

      let(:builder) { ContributionModels::ContributionModelBuilder.new }

      describe "#build_contribution_unit_values" do
        let(:subject) { builder.build_contribution_levels(contribution_model) }

        it "builds the correct number" do
          expect(subject.length).to eq 1
        end

        it "build the specified kind of contribution unit value" do
          expect(subject.first.kind_of?(::BenefitMarkets::MockContributionUnitValue)).to be_truthy
        end

        it "properly assigns the contribution unit" do
          expect(subject.first.contribution_unit_id).to eq contribution_unit.id
        end
      end
    end
  end
end
