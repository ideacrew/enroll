# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application"

RSpec.describe Operations::Eligible::MigrateEligibility,
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

  let(:eligibility_options) do
    {
      eligibility_id: BSON.ObjectId("648c68f288d2410568c95990"),
      eligibility_type:
        "BenefitSponsors::BenefitSponsorships::BenefitSponsorship",
      start_on: Date.today,
      status: nil,
      title: nil,
      created_at: DateTime.now,
      updated_at: DateTime.now
    }
  end

  let(:evidence_options) do
    {
      is_satisfied: true,
      key: :osse_subsidy,
      title: "Evidence for Osse Subsidy",
      created_at: DateTime.now,
      updated_at: DateTime.now
    }
  end

  let(:grant_options) do
    {
      key: :minimum_participation_rule,
      title: "minimum_participation_rule_relaxed_2023",
      start_on: Date.today,
      created_at: DateTime.now,
      updated_at: DateTime.now
    }
  end

  let(:subject_options) do
    {
      key: benefit_sponsorship.to_global_id.to_s,
      klass: "BenefitSponsors::BenefitSponsorships::BenefitSponsorship",
      title: "Subject for Osse Subsidy"
    }
  end

  let(:value_options) do
    {
      key: :minimum_participation_rule,
      title: "minimum_participation_rule_relaxed_2023",
      value: "minimum_participation_rule"
    }
  end

  let(:eligibility) do
    subject = OpenStruct.new(subject_options)
    eligibility = OpenStruct.new(eligibility_options)
    evidence = OpenStruct.new(evidence_options)
    value = OpenStruct.new(value_options)
    grant = OpenStruct.new(grant_options)
    grant.value = value

    eligibility.evidences = [evidence]
    eligibility.grants = [grant]
    eligibility.subject = subject
    eligibility
  end

  context "when existing eligibility record passed with subject" do
    it "should migrate eligibility into new models" do
      result =
        described_class.new.call(
          current_eligibilities: [eligibility],
          eligibility_type: "BenefitSponsors::BenefitSponsorships::BenefitSponsorship"
        )

      expect(result.success?).to be_truthy
      benefit_sponsorship.reload
      eligibility = benefit_sponsorship.eligibilities.last
      expect(eligibility).to be_present

      evidence = eligibility.evidences.last
      expect(evidence.is_satisfied).to be_truthy

      expect(
        evidence.state_histories.pluck(
          :is_eligible,
          :effective_on,
          :from_state,
          :to_state,
          :event
        )
      ).to eq [
           [false, Date.today, :initial, :initial, :move_to_initial],
           [true, Date.today, :initial, :approved, :move_to_approved]
         ]
    end
  end
end
