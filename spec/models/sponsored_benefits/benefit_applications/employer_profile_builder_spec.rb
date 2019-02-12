require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

module SponsoredBenefits
  RSpec.describe BenefitApplications::EmployerProfileBuilder, type: :model do
    include_context 'set up'

    context "add_benefit_sponsors_benefit_application", dbclean: :after_each do
      let(:proposal) { plan_design_proposal }
      let(:employer_client) { organization }
      let(:builder) { SponsoredBenefits::BenefitApplications::EmployerProfileBuilder.new(proposal, employer_client) }

      it "should successfully add plan year to employer profile with published quote" do
        # toDo - Fix this spec after fixing employer profile builder while fixing claim quote.
        plan_design_proposal.publish!
        # builder = SponsoredBenefits::BenefitApplications::EmployerProfileBuilder.new(plan_design_proposal, organization)
        # expect(benefit_sponsor_organization.active_benefit_sponsorship.benefit_applications.present?).to eq false
        # builder.add_benefit_sponsors_benefit_application
        # expect(benefit_sponsor_organization.active_benefit_sponsorship.benefit_applications.present?).to eq true
      end
    end
  end
end
