require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"

module SponsoredBenefits
  RSpec.describe BenefitApplications::EmployerProfileBuilder, type: :model do
    let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }
    let(:effective_period_end_on)   { effective_period_start_on + 1.year - 1.day }
    let(:effective_period)          { effective_period_start_on..effective_period_end_on }

    let(:open_enrollment_period_start_on) { effective_period_start_on.prev_month }
    let(:open_enrollment_period_end_on)   { open_enrollment_period_start_on + 9.days }
    let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

    let(:params) do
      {
        effective_period: effective_period,
        open_enrollment_period: open_enrollment_period,
      }
    end

    context "add_benefit_sponsors_benefit_application", dbclean: :after_each do
      include_context "setup benefit market with market catalogs and product packages"
      let(:benefit_application)       { SponsoredBenefits::BenefitApplications::BenefitApplication.new(params) }
      let(:benefit_sponsorship)       { SponsoredBenefits::BenefitSponsorships::BenefitSponsorship.new(
        benefit_market: "aca_shop_cca",
        enrollment_frequency: "rolling_month"
      )}

      let(:address)  { Address.new(kind: "primary", address_1: "609 H St NE", city: "Washington", state: "DC", zip: "20002", county: "County") }
      let(:phone)  { Phone.new(kind: "main", area_code: "202", number: "555-9999") }
      let(:office_location) { OfficeLocation.new(
          is_primary: true,
          address: address,
          phone: phone
        )
      }
      let(:issuer_profile)     { FactoryBot.create :benefit_sponsors_organizations_issuer_profile, assigned_site: site}
      let(:current_effective_date)  { TimeKeeper.date_of_record }
      let(:benefit_sponsor_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{site.site_key}_employer_profile".to_sym, site: site) }
      let(:sponsor_benefit_sponsorship) do
        sponsorship = benefit_sponsor_organization.employer_profile.add_benefit_sponsorship
        sponsorship.save
        sponsorship
      end

      let(:plan_design_organization)  { SponsoredBenefits::Organizations::PlanDesignOrganization.new(legal_name: "xyz llc", office_locations: [office_location]) }
      let(:plan_design_proposal)      { SponsoredBenefits::Organizations::PlanDesignProposal.new(title: "New Proposal") }
      let(:profile) {SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new}

      let(:product)  { FactoryBot.create :benefit_markets_products_health_products_health_product, issuer_profile: issuer_profile }
      let(:plan )    { FactoryBot.create(:plan, hios_id: product.hios_id) }
      let(:benefit_group)             { FactoryBot.create(:benefit_group, reference_plan_id: plan.id, title: 'benefit group') }

      before(:each) do
        sponsor_benefit_sponsorship.rating_area = rating_area
        sponsor_benefit_sponsorship.service_areas = [service_area]
        sponsor_benefit_sponsorship.save
        plan_design_organization.plan_design_proposals << [plan_design_proposal]
        plan_design_proposal.profile = profile
        profile.benefit_sponsorships = [benefit_sponsorship]
        benefit_sponsorship.benefit_applications = [benefit_application]
        benefit_application.benefit_groups << benefit_group
        plan_design_organization.save
      end

       it "should successfully add plan year to employer profile with published quote" do
        plan_design_proposal.publish!
        builder = SponsoredBenefits::BenefitApplications::EmployerProfileBuilder.new(plan_design_proposal, benefit_sponsor_organization)
        expect(benefit_sponsor_organization.active_benefit_sponsorship.benefit_applications.present?).to eq false
        builder.add_benefit_sponsors_benefit_application
        expect(benefit_sponsor_organization.active_benefit_sponsorship.benefit_applications.present?).to eq true
      end
    end
  end
end
