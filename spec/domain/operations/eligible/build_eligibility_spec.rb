# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application"

RSpec.describe Operations::Eligible::BuildEligibility,
               type: :model,
               dbclean: :after_each do
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

  let(:required_params) do
    {
      subject: benefit_sponsorship.to_global_id,
      effective_date: Date.today,
      evidence_key: :shop_osse_evidence,
      evidence_value: evidence_value,
      event: event,
      eligibility_record: eligibility_record
    }
  end

  let(:evidence_value) { "false" }
  let(:event) { :move_to_denied }
  let(:eligibility_record) { nil }

  context "with input params" do
    let(:event) { :move_to_initial }

    it "should build admin attested evidence options" do
      result = described_class.new.call(required_params)

      expect(result).to be_success
    end

    it "should build evidence options with :initial state" do
      eligibility = described_class.new.call(required_params).success

      evidence = eligibility[:evidences].last
      eligibility_state_history = eligibility[:state_histories].last
      evidence_state_history = evidence[:state_histories].last

      expect(eligibility_state_history[:event]).to eq(:move_to_initial)
      expect(eligibility_state_history[:from_state]).to eq(:initial)
      expect(eligibility_state_history[:to_state]).to eq(:initial)
      expect(eligibility_state_history[:is_eligible]).to be_falsey

      expect(evidence_state_history[:event]).to eq(:move_to_initial)
      expect(evidence_state_history[:from_state]).to eq(:initial)
      expect(evidence_state_history[:to_state]).to eq(:initial)
      expect(evidence_state_history[:is_eligible]).to be_falsey
      expect(evidence[:is_satisfied]).to be_falsey
    end
  end

  context "with event approved" do
    let(:event) { :move_to_approved }
    let(:evidence_value) { "true" }

    it "should build evidence options with :approved state" do
      eligibility = described_class.new.call(required_params).success

      evidence = eligibility[:evidences].last
      eligibility_state_history = eligibility[:state_histories].last
      evidence_state_history = evidence[:state_histories].last

      expect(eligibility_state_history[:event]).to eq(:move_to_published)
      expect(eligibility_state_history[:from_state]).to eq(:initial)
      expect(eligibility_state_history[:to_state]).to eq(:published)
      expect(eligibility_state_history[:is_eligible]).to be_truthy

      expect(evidence_state_history[:event]).to eq(:move_to_approved)
      expect(evidence_state_history[:from_state]).to eq(:initial)
      expect(evidence_state_history[:to_state]).to eq(:approved)
      expect(evidence_state_history[:is_eligible]).to be_truthy
      expect(evidence[:is_satisfied]).to be_truthy
    end
  end

  context "when existing evidence present" do
    let(:evidence_value) { "true" }
    let(:event) { :move_to_approved }
    let(:eligibility_record) { shop_osse_eligibility }

    let!(:shop_osse_eligibility) do
      eligibility =
        build(
          :benefit_sponsors_benefit_sponsorships_shop_osse_eligibilities_shop_osse_eligibility,
          :with_admin_attested_evidence,
          evidence_state: :initial,
          is_eligible: false
        )
      benefit_sponsorship.eligibilities << eligibility
      benefit_sponsorship.save!
      eligibility
    end

    it "should create state history in tandem with existing evidence" do
      eligibility = described_class.new.call(required_params).success

      evidence = eligibility[:evidences].last
      eligibility_state_history = eligibility[:state_histories].last
      evidence_state_history = evidence[:state_histories].last

      expect(eligibility_state_history[:event]).to eq(:move_to_published)
      expect(eligibility_state_history[:from_state]).to eq(:initial)
      expect(eligibility_state_history[:to_state]).to eq(:published)
      expect(eligibility_state_history[:is_eligible]).to be_truthy

      expect(evidence_state_history[:event]).to eq(:move_to_approved)
      expect(evidence_state_history[:from_state]).to eq(:initial)
      expect(evidence_state_history[:to_state]).to eq(:approved)
      expect(evidence_state_history[:is_eligible]).to be_truthy
      expect(evidence[:is_satisfied]).to be_truthy
    end
  end
end
