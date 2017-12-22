require 'rails_helper'

module SponsoredBenefits
  RSpec.describe BenefitSponsorships::BenefitSponsorship, type: :model, dbclean: :after_each do

    let(:initial_enrollment_period)                     { Date.new(2018,5,1)..Date.new(2019,4,30) }
    let(:open_enrollment_period)                        { Date.new(2018,4,1)..Date.new(2019,4,10) }
    let(:annual_enrollment_period_begin_month_of_year)  { initial_enrollment_period.min.month }
    let(:sic_code)                                      { "0111" }
    let(:benefit_market)                                { :aca_shop_cca }
    let(:legal_name)                                    { "ACME Widgets, Inc" }
    let(:entity_kind)                                   { "s_corporation" }
    let(:fein)                                          { "876543218" }

    let(:organization)          { SponsoredBenefits::Organizations::PlanDesignOrganization.new({legal_name: legal_name, entity_kind: entity_kind, fein: fein}) }
    let(:profile)               { SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new({sic_code: sic_code}) }
    let(:proposal)              { SponsoredBenefits::Organizations::PlanDesignProposal.new({proposal: proposal}) }

    let(:benefit_application)   { SponsoredBenefits::BenefitApplications::AcaShopCcaBenefitApplication.new({effective_period: initial_enrollment_period, open_enrollment_period: open_enrollment_period, recorded_sic_code: "54321"}) }

    let(:valid_params) do 
      {
        benefit_market: benefit_market,
        initial_enrollment_period: initial_enrollment_period,
        annual_enrollment_period_begin_month_of_year: annual_enrollment_period_begin_month_of_year,
      }
    end


    context "With an existing Plan Design Organization with a CCA employer profile" do

      it "using #build should successfully embed an instance of the Benefit Sponsorship the Plan Design Organization with a CCA employer profile" 
    end


  end
end



# pdo.profile = SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new({sic_code: "0111"})
# pdo.profile.benefit_sponsorships.build({benefit_market: :aca_shop_cca, initial_enrollment_period: initial_enrollment_period, annual_enrollment_period_begin_month_of_year: 5})
# pdo.profile.benefit_sponsorships[0].benefit_applications << SponsoredBenefits::BenefitApplications::AcaShopCcaBenefitApplication.new({effective_period: initial_enrollment_period, open_enrollment_period: open_enrollment_period, recorded_sic_code: "54321"})
