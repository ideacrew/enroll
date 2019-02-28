require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe 'active_plans_and_issuers', :dbclean => :after_each, type: :helper do
  describe "##retrive" do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let!(:health_products) { create_list(:benefit_markets_products_health_products_health_product,
            5,
            :with_renewal_product, :with_issuer_profile,
            application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year),
            product_package_kinds: [:single_issuer, :metal_level, :single_product],
            assigned_site: site,
            service_area: service_area,
            renewal_service_area: renewal_service_area,
            metal_level_kind: :gold) }

    let(:current_effective_date)    { effective_period_start_on }
    let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }
    let(:effective_period_end_on)   { effective_period_start_on + 1.year - 1.day }
    let(:effective_period)          { effective_period_start_on..effective_period_end_on }

    let(:open_enrollment_period_start_on) { effective_period_start_on.prev_month }
    let(:open_enrollment_period_end_on)   { open_enrollment_period_start_on + 9.days }
    let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

    subject { ActivePlans.retrieve }

    it 'finds initial benefit applications' do
      expect(subject).to include(published_plan_year)
    end

    it 'finds renewing benefit applications' do
    end
  end
end
