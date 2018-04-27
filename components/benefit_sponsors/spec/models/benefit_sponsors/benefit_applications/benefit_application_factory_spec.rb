require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitApplications::BenefitApplicationFactory, type: :model, :dbclean => :after_each do

    describe "constructor" do
      let!(:benefit_sponsorship) {FactoryGirl.create(:benefit_sponsors_benefit_sponsorship, :with_market_profile)}
      let!(:dc_benefit_application) {BenefitApplications::AcaShopDcBenefitApplication.new}
      let!(:cca_benefit_application) {BenefitApplications::AcaShopCcaBenefitApplication.new}
      let!(:dc_args) {{"fte_count" => "5"}}
      let!(:cca_args) {{"recorded_sic_code" => "0113"}}

      it "should assign dc attributes to given benefit applcation" do
        expect(BenefitApplications::AcaShopDcBenefitApplication).to receive(:new).and_return(dc_benefit_application)
        expect(dc_benefit_application.fte_count).to eq 0
        BenefitApplications::BenefitApplicationFactory.new(benefit_sponsorship, dc_args)
        expect(dc_benefit_application.benefit_sponsorship).to eq benefit_sponsorship
        expect(dc_benefit_application.fte_count).to eq 5
      end

      it "should assign cca attributes to given benefit application" do
        expect(BenefitApplications::AcaShopCcaBenefitApplication).to receive(:new).and_return(cca_benefit_application)
        expect(cca_benefit_application.recorded_sic_code).to be_nil
        benefit_sponsorship.benefit_market.update_attributes(site_urn: :cca)
        BenefitApplications::BenefitApplicationFactory.new(benefit_sponsorship, cca_args)
        expect(cca_benefit_application.benefit_sponsorship).to eq benefit_sponsorship
        expect(cca_benefit_application.recorded_sic_code).to eq "0113"
      end
    end

  end

end