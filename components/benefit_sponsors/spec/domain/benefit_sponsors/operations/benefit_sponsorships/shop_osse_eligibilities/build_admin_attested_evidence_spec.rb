# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application"

RSpec.describe BenefitSponsors::Operations::BenefitSponsorships::ShopOsseEligibilities::BuildAdminAttestedEvidence, type: :model, dbclean: :after_each do

  let(:site) { ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_benefit_market }
  let(:employer_organization)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let(:employer_profile)        { employer_organization.employer_profile }

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
      evidence_record: evidence_record
    }
  end

  let(:evidence_value) { 'false' }
  let(:event) { :move_to_denied }
  let(:evidence_record) { nil }

  context 'with input params' do
    let(:event) { :move_to_initial }

    it 'should build admin attested evidence options' do
      result = described_class.new.call(required_params)

      expect(result).to be_success
    end

    it 'should build evidence options with :initial state' do
      evidence = described_class.new.call(required_params).success

      state_history = evidence[:state_histories].last
      expect(state_history[:event]).to eq(:move_to_initial)
      expect(state_history[:from_state]).to eq(:initial)
      expect(state_history[:to_state]).to eq(:initial)
      expect(state_history[:is_eligible]).to eq(false)
      expect(evidence[:is_satisfied]).to eq(false)
    end
  end

  context 'with event approved' do
    let(:event) { :move_to_approved }
    let(:evidence_value) { 'true' }

    it 'should build evidence options with :approved state' do
      evidence = described_class.new.call(required_params).success

      state_history = evidence[:state_histories].last
      expect(state_history[:event]).to eq(:move_to_approved)
      expect(state_history[:from_state]).to eq(:initial)
      expect(state_history[:to_state]).to eq(:approved)
      expect(state_history[:is_eligible]).to eq(true)
      expect(evidence[:is_satisfied]).to eq(true)
    end
  end

  context 'when existing evidence present' do
    let!(:shop_osse_eligibility) do
      eligibility = build(:benefit_sponsors_benefit_sponsorships_shop_osse_eligibilities_shop_osse_eligibility, :with_admin_attested_evidence, evidence_state: :approved, is_eligible: true)
      benefit_sponsorship.shop_eligibilities << eligibility
      benefit_sponsorship.save!
      eligibility
    end

    let(:evidence_record)  { shop_osse_eligibility.evidences.last }
    let(:latest_state_history) { evidence_record.state_histories.last }

    it 'should create state history in tandem with existing evidence' do
      evidence = described_class.new.call(required_params).success
      state_history = evidence[:state_histories].last

      expect(state_history[:event]).to eq(:move_to_denied)
      expect(state_history[:from_state]).to eq(:approved)
      expect(state_history[:to_state]).to eq(:denied)
      expect(state_history[:is_eligible]).to eq(false)
      expect(evidence[:is_satisfied]).to eq(false)
    end
  end
end
