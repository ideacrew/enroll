# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Operations::BenefitMarkets::CreateBenefitSponsorCatalog, dbclean: :after_each do
  before do
    allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year, 10, 12))
  end

  let!(:site) do
    FactoryBot.create(
      :benefit_sponsors_site, :with_benefit_market, :with_benefit_market_catalog_and_product_packages,
      :as_hbx_profile, EnrollRegistry[:enroll_app].setting(:site_key).item
    )
  end
  let(:benefit_market) { site.benefit_markets.first }
  let(:effective_date) { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:market_kind)    { :aca_shop }
  let(:service_areas)  { FactoryBot.create(:benefit_markets_locations_service_area).to_a }
  let(:benefit_sponsorship_id) { BSON::ObjectId.new }

  let(:enrollment_eligibility) do
    double(
      effective_date: effective_date,
      market_kind: market_kind,
      benefit_application_kind: :initial,
      service_areas: service_areas,
      benefit_sponsorship_id: benefit_sponsorship_id,
      osse_min_employer_contribution: false
    )
  end
  let(:params) { { enrollment_eligibility: enrollment_eligibility} }

  context 'sending required parameters' do

    it 'should create BenefitSponsorCatalog' do
      expect(subject.call(params).success?).to be_truthy
      expect(subject.call(params).success).to be_a BenefitMarkets::Entities::BenefitSponsorCatalog
    end
  end
end
