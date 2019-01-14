require 'rails_helper'
Rake.application.rake_require "tasks/update_super_group_ids"
Rake::Task.define_task(:environment)

RSpec.describe 'Migrating carrier specific super group Id', :type => :task do

  before :all do
    @plan = FactoryBot.create(:plan, hios_id: "88806MA0040003-01", active_year: 2017, carrier_special_plan_identifier: nil)
    @plan_non_super_group = FactoryBot.create(:plan, hios_id: "82569MA0200001-01")

    @product = FactoryBot.create(:benefit_markets_products_health_products_health_product, hios_id: "88806MA0040003-01", application_period: Date.new(2017, 1, 1)..Date.new(2017, 12, 31))
    @product_non_super_group = FactoryBot.create(:benefit_markets_products_health_products_health_product, hios_id: "82569MA0200001-01", application_period: Date.new(2017, 1, 1)..Date.new(2017, 12, 31))

    Rake::Task["supergroup:update_plan_id"].invoke
  end

  context "for old model" do
    context "for matching plans" do
      it "should update the carrier_specific_field_value" do
        @plan.reload
        expect(@plan.carrier_special_plan_identifier).to eq "X227"
      end
    end

    context "for non matching plans" do
      it "should not update the carrier_specific_field_value" do
        expect(@plan_non_super_group.carrier_special_plan_identifier).to be nil
      end
    end
  end

  context "for new model" do
    context "for matching plans" do
      it "should update the carrier_specific_field_value" do
        @product.reload
        expect(@product.issuer_assigned_id).to eq "X227"
      end
    end

    context "for non matching plans" do
      it "should not update the carrier_specific_field_value" do
        expect(@product_non_super_group.issuer_assigned_id).to be nil
      end
    end
  end
end
