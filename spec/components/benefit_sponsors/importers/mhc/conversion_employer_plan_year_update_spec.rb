require "rails_helper"

module BenefitSponsors
  RSpec.describe Importers::Mhc::ConversionEmployerPlanYearUpdate, dbclean: :after_each do

    def class_initializer(params={})
      Importers::Mhc::ConversionEmployerPlanYearUpdate.new(params)
    end

    describe "Action #Update", dbclean: :after_each do
      let(:hios_id) {"11821MA0040003"}
      let!(:dental_product) {FactoryGirl.create(:benefit_markets_products_dental_products_dental_product, hios_id: hios_id)}

      let(:contribution_model) {[FactoryGirl.create(:benefit_markets_contribution_models_contribution_model)]}

      let!(:general_sponsorer) {FactoryGirl.create :benefit_sponsors_benefit_sponsorship,
                                                   :with_benefit_market,
                                                   :with_organization_cca_profile,
                                                   :with_initial_benefit_application}

      # we are already creating site in :benefit_sponsors_benefit_sponsorship in this factory
      let(:site) {BenefitSponsors::Site.by_site_key(:cca).first}

      let!(:issuer_profile) {FactoryGirl.create(:benefit_sponsors_organizations_issuer_profile, abbrev: "DDA", assigned_site: site)}

      let(:formed_params) {
        {
            :action => "Update",
            :fein => general_sponsorer.organization.fein,
            :enrolled_employee_count => "1",
            :new_coverage_policy => "First of the month following or coinciding with date of hire",
            :coverage_start => "10/01/2017",
            :carrier => "DELTA DENTAL",
            :plan_selection => "Sole Source",
            :single_plan_hios_id => hios_id,
            :employee_only_rt_contribution => 80,
            :employee_and_spouse_rt_contribution => 80,
            :employer_domestic_partner_rt_contribution => 80,
            :employer_child_under_26_rt_contribution => 80,
            :sponsored_benefit_kind => :dental
        }
      }
      it "should Add a dental sponsored benefit on active benefit application" do
        allow(BenefitMarkets::ContributionModels::ContributionModel).to receive(:where).and_return(contribution_model)
        update_instance = class_initializer(formed_params)
        expect(update_instance.save).to be_truthy
        benefit_packages = general_sponsorer.reload.active_benefit_application.benefit_packages
        sponsored_benefits = benefit_packages.first.sponsored_benefits
        expect(sponsored_benefits.size).to eq 1
        expect(sponsored_benefits.unscoped.size).to eq 2
      end
    end

    describe "Action#update" do
      context "When sponsored benefit kind is health" do
        let(:formed_health_params) {{
            :action => "Update",
            :fein => "rspec-mock",
            :sponsored_benefit_kind => :health
        }
        }
        it "should not update benefit application" do
          update_instance = class_initializer(formed_health_params)
          # we do not want to search for record and validate
          # since it is -ive scenario for checking :health sponsored benefit
          allow(update_instance).to receive(:valid?).and_return(true)
          expect(update_instance.save).to be_falsy
        end
      end

    end
  end
end
