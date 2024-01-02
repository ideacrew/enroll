# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SponsoredBenefits::Forms::PlanDesignProposal, type: :model, dbclean: :after_each do
  context 'osse eligibility' do

    before { TimeKeeper.set_date_of_record_unprotected!(Date.today) }

    let!(:site) { build(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :dc) }
    let!(:current_effective_date)  { TimeKeeper.date_of_record }
    let!(:benefit_market) { site.benefit_markets.first }
    let!(:benefit_market_catalog) do
      create(:benefit_markets_benefit_market_catalog, :with_product_packages,
             benefit_market: benefit_market,
             title: "SHOP Benefits for #{current_effective_date.year}",
             application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
    end
    let!(:organization) do
      create(
        :sponsored_benefits_plan_design_organization,
        sponsor_profile_id: nil,
        sic_code: '0197'
      )
    end

    let!(:persist_proposal) do
      form = described_class.new(params.merge('osse_eligibility' => 'false'))
      form.save
    end

    let(:plan_design_proposal) { organization.reload.plan_design_proposals[0] }
    let(:employer_profile) { plan_design_proposal.profile }
    let(:benefit_sponsorship) { employer_profile.benefit_sponsorships[0] }

    let(:params) do
      {
        'organization' => organization,
        'title' => 'Quote Number Eleven',
        'effective_date' => organization.calculate_start_on_options.last[1],
        'osse_eligibility' => osse_eligibility
      }
    end

    let(:proposal_effective_date)  { current_effective_date + 1.year }
    let(:renewal_benefit_market_catalog) do
      create(:benefit_markets_benefit_market_catalog, :with_product_packages,
             benefit_market: benefit_market,
             title: "SHOP Benefits for #{proposal_effective_date.year}",
             application_period: (proposal_effective_date.beginning_of_year..proposal_effective_date.end_of_year))
    end

    let(:renewal_catalog_eligibility) do
      ::Operations::Eligible::CreateCatalogEligibility.new.call(
        {
          subject: renewal_benefit_market_catalog.to_global_id,
          eligibility_feature: "aca_shop_osse_eligibility",
          effective_date: renewal_benefit_market_catalog.application_period.begin.to_date,
          domain_model:
            "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
        }
      )
    end

    let(:catalog_eligibility) do
      ::Operations::Eligible::CreateCatalogEligibility.new.call(
        {
          subject: benefit_market_catalog.to_global_id,
          eligibility_feature: "aca_shop_osse_eligibility",
          effective_date: benefit_market_catalog.application_period.begin.to_date,
          domain_model:
            "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
        }
      )
    end

    before do
      allow(EnrollRegistry).to receive(:feature_enabled?).and_return(true)
      catalog_eligibility
      renewal_catalog_eligibility
      form = described_class.new(params.merge('proposal_id' => plan_design_proposal.id.to_s))
      form.save
    end

    context 'when true' do
      let(:osse_eligibility) { 'true' }

      it 'should store eligibility' do
        osse_eligibility = benefit_sponsorship.reload.eligibility_on(current_effective_date)
        expect(osse_eligibility).to be_present
        expect(osse_eligibility.is_eligible_on?(current_effective_date)).to be_truthy
        expect(plan_design_proposal.osse_eligibility.present?).to eq true
      end
    end

    context 'when false' do
      let(:osse_eligibility) { 'true' }

      it 'should term eligibility' do
        osse_eligibility = benefit_sponsorship.reload.eligibility_on(
          plan_design_proposal.effective_date
        )
        expect(osse_eligibility.is_eligible_on?(plan_design_proposal.effective_date)).to be_truthy

        form =
          described_class.new(
            params.merge(
              'proposal_id' => plan_design_proposal.id.to_s,
              'osse_eligibility' => 'false'
            )
          )
        form.save

        osse_eligibility = benefit_sponsorship.reload.eligibility_on(
          plan_design_proposal.effective_date
        )
        expect(osse_eligibility.is_eligible_on?(plan_design_proposal.effective_date)).to be_falsey
        expect(plan_design_proposal.osse_eligibility.present?).to eq false
      end
    end
  end
end
