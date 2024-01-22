# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application"

RSpec.describe BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::CreateShopOsseEligibility,
               type: :model,
               dbclean: :around_each do
  include_context "setup benefit market with market catalogs and product packages"

  let(:site) do
    ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_benefit_market
  end
  let(:employer_organization) do
    FactoryBot.create(
      :benefit_sponsors_organizations_general_organization,
      :with_aca_shop_cca_employer_profile,
      site: site
    )
  end
  let(:employer_profile) { employer_organization.employer_profile }

  let!(:benefit_sponsorship) do
    sponsorship = employer_profile.add_benefit_sponsorship
    sponsorship.save!
    sponsorship
  end

  let(:current_effective_date) { Date.new(Date.today.year, 3, 1) }

  let(:catalog_eligibility) do
    catalog_eligibility =
      ::Operations::Eligible::CreateCatalogEligibility.new.call(
        {
          subject: current_benefit_market_catalog.to_global_id,
          eligibility_feature: "aca_shop_osse_eligibility",
          effective_date:
            current_benefit_market_catalog.application_period.begin.to_date,
          domain_model:
            "AcaEntities::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
        }
      )

    catalog_eligibility
  end

  let(:required_params) do
    {
      subject: benefit_sponsorship.to_global_id,
      effective_date: Date.today,
      evidence_key: :shop_osse_evidence,
      evidence_value: evidence_value
    }
  end

  let(:evidence_value) { "false" }

  before do
    TimeKeeper.set_date_of_record_unprotected!(current_effective_date)
    allow(EnrollRegistry).to receive(:feature_enabled?).and_return(true)
    allow(subject).to receive(:publish_event).and_return(Dry::Monads.Success())
    catalog_eligibility
  end

  after { TimeKeeper.set_date_of_record_unprotected!(Date.today) }

  context "with input params" do
    it "should build admin attested evidence options" do
      result = subject.call(required_params)

      expect(result).to be_success
    end

    it "should create eligibility with :initial state evidence" do
      eligibility = subject.call(required_params).success

      evidence = eligibility.evidences.last
      eligibility_state_history = eligibility.state_histories.last
      evidence_state_history = evidence.state_histories.last

      expect(eligibility_state_history.event).to eq(:move_to_ineligible)
      expect(eligibility_state_history.from_state).to eq(:initial)
      expect(eligibility_state_history.to_state).to eq(:ineligible)
      expect(eligibility_state_history.is_eligible).to be_falsey

      expect(evidence_state_history.event).to eq(:move_to_not_approved)
      expect(evidence_state_history.from_state).to eq(:initial)
      expect(evidence_state_history.to_state).to eq(:not_approved)
      expect(evidence_state_history.is_eligible).to be_falsey
      expect(evidence.is_satisfied).to be_falsey
    end
  end

  context "with event approved" do
    let(:evidence_value) { "true" }

    it "should create eligibility with :approved state evidence" do
      eligibility = subject.call(required_params).success

      evidence = eligibility.evidences.last
      eligibility_state_history = eligibility.state_histories.last
      evidence_state_history = evidence.state_histories.last

      expect(eligibility_state_history.event).to eq(:move_to_eligible)
      expect(eligibility_state_history.from_state).to eq(:initial)
      expect(eligibility_state_history.to_state).to eq(:eligible)
      expect(eligibility_state_history.is_eligible).to be_truthy

      expect(evidence_state_history.event).to eq(:move_to_approved)
      expect(evidence_state_history.from_state).to eq(:initial)
      expect(evidence_state_history.to_state).to eq(:approved)
      expect(evidence_state_history.is_eligible).to be_truthy
      expect(evidence.is_satisfied).to be_truthy
    end
  end

  context "with event approved" do
    let(:evidence_value) { "false" }

    it "should create eligibility with :approved state evidence" do
      eligibility = subject.call(required_params).success

      evidence = eligibility.evidences.last
      eligibility_state_history = eligibility.state_histories.last
      evidence_state_history = evidence.state_histories.last

      expect(eligibility_state_history.event).to eq(:move_to_ineligible)
      expect(eligibility_state_history.from_state).to eq(:initial)
      expect(eligibility_state_history.to_state).to eq(:ineligible)
      expect(eligibility_state_history.is_eligible).to be_falsey

      expect(evidence_state_history.event).to eq(:move_to_not_approved)
      expect(evidence_state_history.from_state).to eq(:initial)
      expect(evidence_state_history.to_state).to eq(:not_approved)
      expect(evidence_state_history.is_eligible).to be_falsey
      expect(evidence.is_satisfied).to be_falsey
    end
  end

  context "when existing eligibility present" do
    let(:evidence_value) { "true" }

    let!(:shop_osse_eligibility) do
      eligibility =
        build(
          :benefit_sponsors_shop_osse_eligibility,
          :with_admin_attested_evidence,
          evidence_state: :initial,
          is_eligible: false
        )
      benefit_sponsorship.eligibilities << eligibility
      benefit_sponsorship.save!
      eligibility
    end

    it "should create state history in tandem with existing evidence" do
      eligibility = subject.call(required_params).success

      evidence = eligibility.evidences.last
      eligibility_state_history = eligibility.state_histories.last
      evidence_state_history = evidence.state_histories.last

      expect(eligibility_state_history.event).to eq(:move_to_eligible)
      expect(eligibility_state_history.from_state).to eq(:ineligible)
      expect(eligibility_state_history.to_state).to eq(:eligible)
      expect(eligibility_state_history.is_eligible).to be_truthy

      expect(evidence_state_history.event).to eq(:move_to_approved)
      expect(evidence_state_history.from_state).to eq(:initial)
      expect(evidence_state_history.to_state).to eq(:approved)
      expect(evidence_state_history.is_eligible).to be_truthy
      expect(evidence.is_satisfied).to be_truthy
    end
  end

  describe "#eligibility_event_for" do
    subject(:instance) { described_class.new }

    before { instance.prospective_eligibility = prospective_eligibility }

    context "when current_state is eligible" do
      let(:current_state) { :eligible }

      context "when prospective_eligibility is true" do
        let(:prospective_eligibility) { true }

        it "should return eligibility renewed event" do
          expect(instance.send(:eligibility_event_for, current_state)).to eq(
            "events.benefit_sponsors.benefit_sponsorships.eligibilities.shop_osse_eligibility.eligibility_renewed"
          )
        end
      end

      context "when prospective_eligibility is false" do
        let(:prospective_eligibility) { false }

        it "should return eligibility created event" do
          expect(instance.send(:eligibility_event_for, current_state)).to eq(
            "events.benefit_sponsors.benefit_sponsorships.eligibilities.shop_osse_eligibility.eligibility_created"
          )
        end
      end
    end

    context "when current_state is ineligible" do
      let(:current_state) { :ineligible }

      context "when prospective_eligibility is true" do
        let(:prospective_eligibility) { true }

        it "should return eligibility renewed event" do
          expect(instance.send(:eligibility_event_for, current_state)).to eq(
            "events.benefit_sponsors.benefit_sponsorships.eligibilities.shop_osse_eligibility.eligibility_renewed"
          )
        end
      end

      context "when prospective_eligibility is false" do
        let(:prospective_eligibility) { false }

        it "should return eligibility terminated event" do
          expect(instance.send(:eligibility_event_for, current_state)).to eq(
            "events.benefit_sponsors.benefit_sponsorships.eligibilities.shop_osse_eligibility.eligibility_terminated"
          )
        end
      end
    end
  end
end
