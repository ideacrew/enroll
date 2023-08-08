# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

#rspec for OsseEligibilityService
module BenefitSponsors
  RSpec.describe ::BenefitSponsors::Services::OsseEligibilityService, type: :model, :dbclean => :after_each do

    let!(:site)  { FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let!(:employer_profile)    { organization.employer_profile }
    let!(:benefit_sponsorship) do
      employer_profile.add_benefit_sponsorship
      employer_profile.benefit_sponsorships.first.save!
      employer_profile.active_benefit_sponsorship
    end
    let(:current_date) { TimeKeeper.date_of_record }
    let(:params) { {osse: { current_date.year.to_s => "true", current_date.last_year.year.to_s => "false" } } }
    let(:subject) { described_class.new(employer_profile, params) }

    describe "#osse_eligibility_years_for_display" do
      it "returns sorted and reversed osse eligibility years" do
        expect(subject.osse_eligibility_years_for_display).to eq(
          ::BenefitMarkets::BenefitMarketCatalog.osse_eligibility_years_for_display.sort.reverse
        )
      end
    end

    describe "#osse_status_by_year" do
      before do
        osse_eligibility_years = [current_date.year, current_date.last_year.year, current_date.next_year.year]
        allow(::BenefitMarkets::BenefitMarketCatalog).to receive(:osse_eligibility_years_for_display).and_return osse_eligibility_years
        ::BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::CreateShopOsseEligibility.new.call(
          {
            subject: benefit_sponsorship.to_global_id,
            evidence_key: :shop_osse_evidence,
            evidence_value: "true",
            effective_date: TimeKeeper.date_of_record.beginning_of_year
          }
        )
        benefit_sponsorship.reload
      end

      it "returns osse status by year" do
        result = subject.osse_status_by_year
        expect(result[current_date.last_year.year][:is_eligible]).to eq(false)
        expect(result[current_date.next_year.year][:is_eligible]).to eq(false)
        expect(result[current_date.year][:is_eligible]).to eq(true)
        expect(result[current_date.year][:start_on]).to eq(current_date.beginning_of_year)
        expect(result[current_date.year][:end_on]).to eq(current_date.end_of_year)
      end
    end

    describe "#get_osse_term_date" do
      it "returns term date based on published_on" do
        result = subject.get_osse_term_date(TimeKeeper.date_of_record.last_year)
        expect(result).to eq(TimeKeeper.date_of_record.last_year)

        result = subject.get_osse_term_date(TimeKeeper.date_of_record.beginning_of_year)
        expect(result).to eq(TimeKeeper.date_of_record)
      end
    end

    describe "#update_osse_eligibilities_by_year" do
      it "updates osse eligibilities by year" do
        allow(subject).to receive(:create_or_term_osse_eligibility).and_return("Success")

        result = subject.update_osse_eligibilities_by_year

        expect(result).to eq({ "Success" => [current_date.year.to_s]})
      end
    end

    describe "#create_or_term_osse_eligibility" do
      it "creates or terms osse eligibility" do
        allow(::BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::CreateShopOsseEligibility.new).to receive(:call).and_return(double("Result", success?: true))

        result = subject.create_or_term_osse_eligibility(benefit_sponsorship, "true", TimeKeeper.date_of_record.beginning_of_year)

        expect(result).to eq("Success")
      end

      it "returns Failure if operation fails" do
        result = subject.create_or_term_osse_eligibility(benefit_sponsorship, "true", Date.today.to_s)

        expect(result).to eq("Failure")
      end
    end
  end
end


