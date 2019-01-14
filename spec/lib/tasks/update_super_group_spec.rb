require 'rails_helper'

describe 'update_super_group' do
  before :all do
    @plan = FactoryBot.create(:plan, hios_id: "88806MA0040003-01", active_year: 2017, carrier_special_plan_identifier: "NHPHM5-87DV")
    @plan2 = FactoryBot.create(:plan, hios_id: "88806MA0040003-01", active_year: 2018, carrier_special_plan_identifier: nil)
    @plan_non_super_group = FactoryBot.create(:plan, hios_id: "82569MA0200001-01")

    @product = FactoryBot.create(:benefit_markets_products_health_products_health_product, hios_id: "88806MA0040003-01", issuer_assigned_id: "NHPHM5-87DV", application_period: Date.new(2017, 1, 1)..Date.new(2017, 12, 31))
    @product2 = FactoryBot.create(:benefit_markets_products_health_products_health_product, hios_id: "88806MA0040003-01", issuer_assigned_id: nil, application_period: Date.new(2018, 1, 1)..Date.new(2018, 12, 31))
    @product_non_super_group = FactoryBot.create(:benefit_markets_products_health_products_health_product, hios_id: "82569MA0200001-01", application_period: Date.new(2017, 1, 1)..Date.new(2017, 12, 31))

    Rake.application.rake_require "tasks/update_super_group"
    Rake::Task.define_task(:environment)
  end

  before :context do
    ENV["active_year"] = "2018"
    ENV["hios_id"] = "88806MA0040003-01"
    ENV["super_group_id"] = "NHPHM5-86DV"
  end

  context "it should update super_group_id correctly" do
    it "should be nil before running task" do
      expect(@plan2.carrier_special_plan_identifier).to eq nil
      expect(@product2.issuer_assigned_id).to eq nil
    end

    it "should update the plan/products with super_group_id after rake task" do
      invoke_task
      @plan2.reload
      @product2.reload
      expect(@plan2.carrier_special_plan_identifier).to eq ENV["super_group_id"]
      expect(@product2.issuer_assigned_id).to eq ENV["super_group_id"]
    end

    it "should not update other plans with non matching env variables, after rake task" do
      expect(@plan.carrier_special_plan_identifier).to eq "NHPHM5-87DV"
      expect(@plan_non_super_group.carrier_special_plan_identifier).to eq nil
    end

    it "should not update other products with non matching env variables, after rake task" do
      expect(@product.issuer_assigned_id).to eq "NHPHM5-87DV"
      expect(@product_non_super_group.issuer_assigned_id).to eq nil
    end
  end

  after :all do
    DatabaseCleaner.clean
  end
end

def invoke_task
  Rake::Task["migrations:update_super_group"].reenable
  Rake::Task["migrations:update_super_group"].invoke
end

