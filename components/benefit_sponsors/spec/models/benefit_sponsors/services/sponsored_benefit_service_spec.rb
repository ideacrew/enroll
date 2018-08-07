require "rails_helper"

RSpec.describe do
  let(:site)                  { build(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let(:benefit_sponsor)        { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile_initial_application, site: site) }
  let(:benefit_sponsorship)    { benefit_sponsor.active_benefit_sponsorship }
  let(:benefit_application)    { benefit_sponsorship.benefit_applications.first }
  let(:benefit_package)    { benefit_application.benefit_packages.first }

  let(:current_effective_date)  { TimeKeeper.date_of_record }
  let(:benefit_market)      { site.benefit_markets.first }
  let(:benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
    benefit_market: benefit_market,
    title: "SHOP Benefits for #{current_effective_date.year}",
    application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
  }
  let(:issuer_profile)  { FactoryGirl.create :benefit_sponsors_organizations_issuer_profile, assigned_site: site}
  let(:product_package_kind) { :single_product}
  let(:product_package) { benefit_market_catalog.product_packages.where(package_kind: product_package_kind).first }
  let(:product) { product_package.products.first }
  let(:contribution_model) { product_package.contribution_model }

  let(:employee_contribution_unit) { contribution_model.contribution_units.where(order: 0).first }
  let(:spouse_contribution_unit) { contribution_model.contribution_units.where(order: 1).first }
  let(:partner_contribution_unit) { contribution_model.contribution_units.where(order: 2).first }
  let(:child_contribution_unit) { contribution_model.contribution_units.where(order: 3).first }

  let(:attrs) {
    {
      benefit_package_id: benefit_package.id,
      kind: :dental
    }
  }

  describe "while creating a sponsored benefit", dbclean: :after_each do

    let(:benefits_params) {
      {
        :kind => "dental",
        :benefit_package_id => benefit_package.id,
        :benefit_sponsorship_id => benefit_sponsorship.id,
        :sponsored_benefits_attributes => sponsored_benefits_params
      }
    }

    let(:sponsored_benefits_params) {
      {
        "0" => {
          :sponsor_contribution_attributes => sponsor_contribution_attributes,
          :product_package_kind => product_package_kind,
          :kind => "dental",
          :product_option_choice => issuer_profile.legal_name,
          :reference_plan_id => product.id.to_s
        }
      }
    }

    let(:sponsor_contribution_attributes) {
      {
      :contribution_levels_attributes => contribution_levels_attributes
      }
    }

    let(:contribution_levels_attributes) {
      {
        "0" => {:is_offered => "true", :display_name => "Employee", :contribution_factor => "95", contribution_unit_id: employee_contribution_unit },
        "1" => {:is_offered => "true", :display_name => "Spouse", :contribution_factor => "85", contribution_unit_id: spouse_contribution_unit },
        "2" => {:is_offered => "true", :display_name => "Domestic Partner", :contribution_factor => "75", contribution_unit_id: partner_contribution_unit },
        "3" => {:is_offered => "true", :display_name => "Child Under 26", :contribution_factor => "75", contribution_unit_id: child_contribution_unit }
      }
    }

    let(:create_form) { BenefitSponsors::Forms::BenefitForm.new(benefits_params) }
    let(:subject) { BenefitSponsors::Services::SponsoredBenefitService.new(attrs) }

    it "should not have dental sponsored benefits" do
      expect(benefit_package.dental_sponsored_benefit).to eq nil
    end

    context "#form_params_to_attributes" do

      let(:create_result) { subject.form_params_to_attributes(create_form) }

      it "should not have sponsored benefit id" do
        expect(create_result.keys.include?(:id)).to eq false
      end

      it "should have selected reference_plan_id" do
        expect(create_result[:reference_plan_id]).to eq product.id.to_s
      end

      it "should have selected product_package_kind" do
        expect(create_result[:product_package_kind]).to eq product_package_kind.to_s
      end

      it "should have selected product_option_choice(Issuer legal name)" do
        expect(create_result[:product_option_choice]).to eq issuer_profile.legal_name
      end

      it "should have contribution_levels_attributes" do
        expect(create_result[:sponsor_contribution_attributes].keys.include?(:contribution_levels_attributes)).to eq true
      end

      it "should have 4 contribution_levels_attributes" do # we always have 4 for dental
        expect(create_result[:sponsor_contribution_attributes][:contribution_levels_attributes][0].size).to eq 4
      end
    end

    context "#save", dbclean: :after_each do

      before do
        subject.save(create_form)
        benefit_package.reload
      end

      it "should create new dental sponsored benefits" do
        expect(benefit_package.dental_sponsored_benefit).not_to eq nil
      end

      it "should create contribution levels for newly created dental sponsored benefits" do
        expect(benefit_package.dental_sponsored_benefit.sponsor_contribution.contribution_levels.size).to eq 4
      end
    end
  end

  describe "while updating a sponsored benefit" do
    context "#form_params_to_attributes" do
      it "should have sponsored benefit id" do
        # TODO
      end
    end

    context "#save" do
      it "should update dental sponsored benefits" do
        # TODO
      end
    end
  end
end
