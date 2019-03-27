require 'rails_helper'

RSpec.describe 'load_dental_pricing_and_contribution_models', :type => :task do
  before :all do
    Rake.application.rake_require "tasks/migrations/plans/load_dental_pricing_and_contribution_models"
    Rake::Task.define_task(:environment)
  end

  before :context do
    invoke_models_task
  end

  context "load pricing model" do
    it "should have one pricing record" do
      pm= BenefitMarkets::PricingModels::PricingModel.where(price_calculator_kind: "::BenefitSponsors::PricingCalculators::ShopSimpleListBillPricingCalculator")
      expect(pm.count).to be 1
    end
  end

  context "load contribution model" do
    it "should have one contribution record" do
      cm = BenefitMarkets::ContributionModels::ContributionModel.where(contribution_calculator_kind: "::BenefitSponsors::ContributionCalculators::SimpleShopReferencePlanContributionCalculator")
      expect(cm.count).to be 1
    end
  end
  after(:all) do
    DatabaseCleaner.clean
  end
end

private

def invoke_models_task
  Rake::Task["seed:dental_contribution_and_pricing_model"].reenable
  Rake::Task["seed:dental_contribution_and_pricing_model"].invoke
end
