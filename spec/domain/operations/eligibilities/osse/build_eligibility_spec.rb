# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers.rb"

RSpec.describe ::Operations::Eligibilities::Osse::BuildEligibility,
               type: :model,
               dbclean: :after_each do

  let(:site) { ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_benefit_market }
  let(:benefit_market)  { site.benefit_markets.first }
  let(:dc_employer_organization)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, site: site) }
  let(:dc_profile)                 { dc_employer_organization.employer_profile  }
  let(:benefit_sponsorship)         { dc_profile.add_benefit_sponsorship }
  let(:subject_ref) { benefit_sponsorship.to_global_id }
  let(:effective_date) { TimeKeeper.date_of_record }

  let(:required_params) do
    {
      subject_gid: subject_ref,
      evidence_key: :osse_subsidy,
      evidence_value: "true",
      effective_date: effective_date
    }
  end

  before do
    benefit_sponsorship.save!
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'when required attributes passed' do

    it 'should be success' do
      result = subject.call(required_params)
      expect(result.success?).to be_truthy
    end

    it 'should create eligibility' do
      result = subject.call(required_params)
      expect(result.success).to be_a(AcaEntities::Eligibilities::Osse::Eligibility)
    end
  end

  context 'when required attributes not passed' do
    it 'should fail with validation error' do
      result = subject.call(required_params.except(:effective_date))
      expect(result.failure?).to be_truthy
      expect(result.failure).to include("effective date missing")
    end
  end
end
