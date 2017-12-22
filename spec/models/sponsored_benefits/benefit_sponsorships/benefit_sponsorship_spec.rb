require 'rails_helper'

module SponsoredBenefits
  RSpec.describe BenefitSponsorships::BenefitSponsorship, type: :model, dbclean: :after_each do

    let(:initial_enrollment_period)                     { Date.new(2018,5,1)..Date.new(2019,4,30) }
    let(:open_enrollment_period)                        { Date.new(2018,4,1)..Date.new(2019,4,10) }
    let(:annual_enrollment_period_begin_month)          { initial_enrollment_period.min.month }
    let(:sic_code)                                      { '0111' }
    let(:benefit_market)                                { :aca_shop_cca }
    let(:legal_name)                                    { 'ACME Widgets, Inc' }
    let(:entity_kind)                                   { 's_corporation' }
    let(:fein)                                          { '876543218' }
    let(:title)                                         { 'Proposal for prospective CCA employer'}

    let(:organization)        { SponsoredBenefits::Organizations::PlanDesignOrganization.new({legal_name: legal_name, entity_kind: entity_kind, fein: fein}) }
    let(:proposal)            { SponsoredBenefits::Organizations::PlanDesignProposal.new({proposal: proposal}) }
    let(:profile)             { SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new({sic_code: sic_code}) }

    let(:benefit_application) { SponsoredBenefits::BenefitApplications::AcaShopCcaBenefitApplication.new({effective_period: initial_enrollment_period, open_enrollment_period: open_enrollment_period, recorded_sic_code: "54321"}) }

    let(:valid_params) do 
      {
        benefit_market: benefit_market,
        initial_enrollment_period: initial_enrollment_period,
        annual_enrollment_period_begin_month: annual_enrollment_period_begin_month,
      }
    end


    context "With an existing Plan Design Organization with a Plan Design Proposal" do

      it "using #build should successfully embed an instance of the Benefit Sponsorship the Plan Design Organization with a CCA employer profile" do
        proposal  = organization.plan_design_proposals.build(title: title, profile: profile)
        profile   = proposal.profile
        benefit_sponsorship = profile.benefit_sponsorships.build(
                                { 
                                  benefit_market: :aca_shop_cca, 
                                  initial_enrollment_period: initial_enrollment_period, 
                                  annual_enrollment_period_begin_month: annual_enrollment_period_begin_month,
                                  }
                                )
        expect(benefit_sponsorship.annual_enrollment_period_begin_month).to eq annual_enrollment_period_begin_month
      end
    end


  end
end



# pdo.profile = SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new({sic_code: "0111"})
# pdo.profile.benefit_sponsorships.build({benefit_market: :aca_shop_cca, initial_enrollment_period: initial_enrollment_period, annual_enrollment_period_begin_month: 5})
# pdo.profile.benefit_sponsorships[0].benefit_applications << SponsoredBenefits::BenefitApplications::AcaShopCcaBenefitApplication.new({effective_period: initial_enrollment_period, open_enrollment_period: open_enrollment_period, recorded_sic_code: "54321"})
