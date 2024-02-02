# frozen_string_literal: true

require 'rails_helper'

describe 'applicant_outreach_report', :dbclean => :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  let(:service_areas) { FactoryBot.create(:benefit_markets_locations_service_area).to_a }
  let(:product_1) { FactoryBot.create(:product, title: "Maine's Choice Healthcare", service_area_id: service_areas.first.id) }
  let(:product_2) { FactoryBot.create(:product, title: "Maine's Best Healthcare", service_area_id: service_areas.first.id) }
  let(:product_3) { FactoryBot.create(:product, title: "State Healthcare", service_area_id: service_areas.first.id) }

  context 'when sanitizing all plans' do
    before do
      invoke_plan_sanitization
    end

    it "should have no plans with titles containing the substring 'Maine'" do
      maine_plans = BenefitMarkets::Products::Product.where(title: /maine/i)

      expect(maine_plans.size).to eq(0)
    end
  end
end

def invoke_plan_sanitization
  plan_sanitizationer = File.join(Rails.root, "script/sanitize_plan_info.rb")
  load plan_sanitizationer
end
