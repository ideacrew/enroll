# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers.rb"

RSpec.describe ::Operations::Eligibilities::Osse::GenerateGrants,
               type: :model,
               dbclean: :after_each do

  let(:site) { ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_benefit_market }
  let(:benefit_market)  { site.benefit_markets.first }
  let(:dc_employer_organization)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, site: site) }
  let(:dc_profile)                 { dc_employer_organization.employer_profile  }
  let(:benefit_sponsorship)         { dc_profile.add_benefit_sponsorship }
  let(:subject_ref) { benefit_sponsorship.to_global_id }
  let(:effective_date) { Date.new(2023,1,1) }
  let(:evidence_key) { :osse_subsidy }

  let!(:eligibility) do
    benefit_sponsorship.save!
    result = ::Operations::Eligibilities::Osse::BuildEligibility.new.call({
                                                                            subject_gid: subject_ref,
                                                                            evidence_key: evidence_key,
                                                                            evidence_value: "true",
                                                                            effective_date: effective_date
                                                                          })

    eligibility = benefit_sponsorship.eligibilities.build(result.success.to_h)
    eligibility.save!
    eligibility
  end

  let(:required_params) do
    {
      eligibility_gid: eligibility.to_global_id,
      evidence_key: evidence_key
    }
  end

  let(:grant_keys) do
    feature = EnrollRegistry["#{benefit_sponsorship.market_kind}_benefit_sponsorship_#{evidence_key}_#{effective_date.year}"]
    feature.setting(:grants_offered).item.collect do |key|
      EnrollRegistry[key].item
    end
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'when required attributes passed' do

    it 'should be success' do
      result = subject.call(required_params)
      expect(result.success?).to be_truthy
    end

    it 'should return grants' do
      result = subject.call(required_params)

      expect(result.success).to be_an_instance_of(Array)
      expect(result.success.map(&:key)).to eq grant_keys
    end
  end

  context 'when required attributes not passed' do
    it 'should fail with validation error' do
      result = subject.call(required_params.except(:evidence_key))
      expect(result.failure?).to be_truthy
      expect(result.failure).to include("evidence key missing")
    end
  end
end
