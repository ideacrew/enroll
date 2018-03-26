require "rails_helper"

module BenefitMarkets
  RSpec.describe ContributionModels::FehbContributionModel do
    describe "given a contribution unit" do
      let(:contribution_unit) do
        ContributionModels::ContributionUnit.new(
          name: "employee_only",
          order: 0
        )
      end
      let(:contribution_units) { [contribution_unit] }

      let(:contribution_model) do
        ContributionModels::FehbContributionModel.new(
          :contribution_units => contribution_units,
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
