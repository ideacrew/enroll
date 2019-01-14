require 'rails_helper'

RSpec.describe "_benefit_groups.html.slim", :type => :view, dbclean: :after_each do

  describe "rendering the widget on benefit group page template" do

    let!(:sponsorship) {FactoryBot.build :benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile, :with_initial_benefit_application}
    let(:benefit_group) {sponsorship.benefit_applications.first.benefit_packages.first}
    let!(:service) {instance_double("BenefitSponsors::Services::SponsoredBenefitCostEstimationService")}
    let(:estimator) {
      {
          :estimated_total_cost => 619.00,
          :estimated_enrollee_minimum => 75.00,
          :estimated_enrollee_maximum => 60.00
      }
    }
    let!(:issuer_profile) {BenefitSponsors::Organizations::IssuerProfile.new}

    before :each do
      allow(BenefitSponsors::Organizations::IssuerProfile).to receive(:find).and_return issuer_profile
      allow(issuer_profile).to receive(:legal_name).and_return "rspec-carrier_legal_name"
      stub_template 'ui-components/v1/tables/benefit_package_summary' => "Do nothing"
      allow(::BenefitSponsors::Services::SponsoredBenefitCostEstimationService).to receive(:new).and_return(service)
      allow(service).to receive(:calculate_estimates_for_home_display).with(benefit_group.sponsored_benefits.first).and_return(estimator)
    end

    it "should display one carrier for plans by row" do
      render :partial => "ui-components/v1/cards/benefit_groups.html.slim", :locals => {:bg => benefit_group}
      expect(rendered).to have_selector('td', text: /One Carrier/i)
    end

    it "should display A single plan for plans by row" do
      allow(benefit_group.sponsored_benefits.first).to receive(:product_package_kind).and_return(:single_product)
      render :partial => "ui-components/v1/cards/benefit_groups.html.slim", :locals => {:bg => benefit_group}
      expect(rendered).to have_selector('td', text: /A Single Plan/i)
    end

    it "should display one level for plans by row" do
      allow(benefit_group.sponsored_benefits.first).to receive(:product_package_kind).and_return(:metal_level)
      render :partial => "ui-components/v1/cards/benefit_groups.html.slim", :locals => {:bg => benefit_group}
      expect(rendered).to have_selector(:xpath, './/*[@id="employer-benefit-groups"]/div[2]/div/table')
      expect(rendered).to have_selector('td', text: /One Level/i)
    end
  end
end
