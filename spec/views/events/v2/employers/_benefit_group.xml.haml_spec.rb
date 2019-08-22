require 'rails_helper'

describe "app/views/events/v2/employers/_benefit_group.xml.haml", dbclean: :around_each do
  let!(:site)  { FactoryBot.create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, :with_benefit_market_catalog_and_product_packages, :cca) }
  let!(:benefit_market) { site.benefit_markets.first }
  let!(:benefit_market_catalog)  { benefit_market.benefit_market_catalogs.first }
  let(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization,:with_aca_shop_cca_employer_profile_initial_application, site:site)}
  let(:employer_profile) {organization.employer_profile}
  let(:benefit_package) { employer_profile.latest_benefit_application.benefit_packages.first }
  let!(:health_sponsored_benefit) {benefit_package.health_sponsored_benefit}

  context "benefit_group xml" do
    context "reference plan" do
      before :each do
        render :template => "events/v2/employers/_benefit_group.xml.haml", locals: {benefit_group: benefit_package,
                                                                                    elected_plans: [], relationship_benefits: [],sponsored_benefit:health_sponsored_benefit}
        @doc = Nokogiri::XML(rendered)
      end

      it "does not include reference plan" do
        expect(@doc.xpath("//reference_plan").count).to eq(0)
      end

      it "should not include rating area for DC" do
        expect(@doc.xpath("//rating_area").count).to eq(0)
      end
    end
  end

  context "FEHB employer" do
    let(:employer_profile) {organization.employer_profile}
    let(:benefit_package) { employer_profile.latest_benefit_application.benefit_packages.first }
    let!(:health_sponsored_benefit) {benefit_package.health_sponsored_benefit}
    let!(:update_contribution) do
      benefit_sponsor_catalog = benefit_package.benefit_sponsor_catalog
      product_package =  benefit_sponsor_catalog.product_packages.where(package_kind: :single_issuer).first
      contribution_units = product_package.contribution_model.contribution_units
      contribution_units.where(name: 'employee').first.update_attributes(name: "employee_only")
      contribution_units.where(name: 'spouse').first.update_attributes(name: "employee_plus_one")
      contribution_units.where(name: 'dependent').first.update_attributes(name: "family")
      benefit_sponsor_catalog.save!
    end


    context "relationship_benefits" do
      before :each do
        allow(organization).to receive(:is_a_fehb_profile?).and_return(true)
        render :template => "events/v2/employers/_benefit_group.xml.haml", locals: {benefit_group: benefit_package, elected_plans: [], relationship_benefits: health_sponsored_benefit.sponsor_contribution.contribution_levels,
                                                                                    sponsored_benefit: health_sponsored_benefit}
        @doc = Nokogiri::XML(rendered)
      end

      it "should include old modal contribution levels" do
        expect(@doc.xpath("//relationship_benefit").count).to eq(4)
        expect(@doc.xpath("//relationship_benefit[1]//relationship").text).to eq "urn:openhbx:terms:v1:employee_census_relationship#employee"
        expect(@doc.xpath("//relationship_benefit[2]//relationship").text).to eq "urn:openhbx:terms:v1:employee_census_relationship#spouse"
        expect(@doc.xpath("//relationship_benefit[3]//relationship").text).to eq "urn:openhbx:terms:v1:employee_census_relationship#domestic_partner"
        expect(@doc.xpath("//relationship_benefit[4]//relationship").text).to eq "urn:openhbx:terms:v1:employee_census_relationship#child_under_26"
      end

      it "should not offer domestic_partner for fehb" do
        expect(@doc.xpath("//relationship_benefit[3]//relationship").text).to eq "urn:openhbx:terms:v1:employee_census_relationship#domestic_partner"
        expect(@doc.xpath("//relationship_benefit[3]//contribution_percent").text).to eq "0.0"
        expect(@doc.xpath("//relationship_benefit[3]//offered").text).to eq "false"
      end


      it "should not include new modal contribution levels" do
        expect(@doc.xpath("//relationship_benefit[1]//relationship").text).not_to eq "urn:openhbx:terms:v1:employee_census_relationship#employee_only"
      end
    end
  end
end
