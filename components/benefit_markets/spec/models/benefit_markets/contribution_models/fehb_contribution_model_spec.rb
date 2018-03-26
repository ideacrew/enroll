require "rails_helper"

module BenefitMarkets
  RSpec.describe ContributionModels::FehbContributionModel do
    describe "given:
- a contribution unit
- a member relationship
" do
      let(:contribution_unit) do
        ContributionModels::ContributionUnit.new(
          name: "employee_only",
          display_name: "Employee Only",
          default_offering: true,
          member_relationship_maps: [member_relationship_map],
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
          :contribution_units => contribution_units,
          :member_relationships => member_relationships,
          :name => "Federal Heath Benefits"
        )
      end

      after :each do
         ContributionModels::FehbContributionModel.where("_id" => contribution_model.id).delete 
      end

      subject do
        contribution_model.save!
        ContributionModels::FehbContributionModel.find(contribution_model.id)        
      end

      it "returns the right subclass comming back from the contribution_unit" do
        saved_contribution_model = subject.contribution_units.first.contribution_model
        expect(saved_contribution_model.kind_of?(ContributionModels::FehbContributionModel)).to be_truthy
      end
    end
  end
end
