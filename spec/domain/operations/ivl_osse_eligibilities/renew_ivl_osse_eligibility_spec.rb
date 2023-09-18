# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Operations::IvlOsseEligibilities::RenewIvlOsseEligibility,
               type: :model,
               dbclean: :around_each do
  let(:coverage_year) { Date.today.year }

  let(:hbx_profile) do
    FactoryBot.create(
      :hbx_profile,
      :last_years_coverage_period,
      coverage_year: coverage_year
    )
  end

  let(:benefit_coverage_period) do
    hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect do |bcp|
      (bcp.start_on.year == coverage_year) &&
        bcp.start_on > bcp.open_enrollment_start_on
    end
  end

  let(:catalog_eligibility) do
    Operations::Eligible::CreateCatalogEligibility.new.call(
      {
        subject: benefit_coverage_period.to_global_id,
        eligibility_feature: "aca_ivl_osse_eligibility",
        effective_date: benefit_coverage_period.start_on.to_date,
        domain_model:
          "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
      }
    )
  end

  let(:person) { FactoryBot.create(:person, :with_family, :with_consumer_role) }
  let!(:consumer_role) { person.consumer_role }

  let(:prospective_date) { TimeKeeper.date_of_record.end_of_year.next_day }
  let(:prospective_year) { prospective_date.year }

  let(:required_params) { { effective_date: prospective_date } }

  let(:sponsorship) { HbxProfile.current_hbx.benefit_sponsorship }

  before do
    allow(EnrollRegistry).to receive(:feature_enabled?).and_return(true)
    catalog_eligibility
  end

  def coverage_period
    sponsorship.reload.benefit_coverage_periods.by_year(prospective_year).first
  end

  context "with input params" do
    it "should return success" do
      result = described_class.new.call(required_params)
      expect(result).to be_success
    end

    it "should create eligibility with :initial state evidence" do
      expect(coverage_period).to be_blank
      described_class.new.call(required_params)

      expect(coverage_period).to be_present
      expect(coverage_period.eligibilities).to be_present
      expect(coverage_period.eligibilities.pluck(:key)).to eq [
           :"aca_ivl_osse_eligibility_#{prospective_year}"
         ]
    end

    it "should trigger ivl eligibility renewal event" do
      result = described_class.new.call(required_params)
      expect(result.success).to be_a(Events::BatchProcess::BatchEventsRequested)
      payload = result.success.payload

      expect(
        payload[:batch_handler]
      ).to eq "::Operations::Eligible::EligibilityBatchHandler"
      expect(payload[:record_kind]).to eq :individual
      expect(payload[:effective_date]).to eq prospective_date
    end
  end

  context "with invalid date" do
    let(:required_params) { { effective_date: "2024-1-1" } }

    it "should fail date validation" do
      result = described_class.new.call(required_params)
      expect(result).to be_failure
    end
  end
end
