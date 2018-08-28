require "rails_helper"

module BenefitSponsors

  describe Importers::Mhc::ConversionEmployerDentalImport, db_clean: :after_each do

    let!(:site) { FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, :cca)}
    let!(:issuer_profile) { FactoryGirl.create(:benefit_sponsors_organizations_issuer_profile, assigned_site: site)}
    let!(:dental_products) {
      create_list(:benefit_markets_products_dental_products_dental_product,
                                         4,
                                         application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year),
                                         product_package_kinds: [:single_product],
                                         service_area: service_area,
                                         # issuer_profile_id: issuer_profile.id,
                                         metal_level_kind: :gold) }


    let(:organization) {
      FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile_initial_application, site: site)

    }
    let(:current_effective_date) { organization.benefit_sponsorships.first.benefit_applications.first.effective_period.min}
    let(:service_area) { organization.benefit_sponsorships.first.benefit_applications.first.recorded_service_areas.first }



    let(:benefit_application) { organization.benefit_sponsorships.first.benefit_applications.first}

    let!(:record_attrs) {{
        :action => "Add",
        :fein => organization.fein,
        :enrolled_employee_count => "1",
        :new_coverage_policy => "First of the month following or coinciding with date of hire",
        :coverage_start => "10/01/2017",
        :carrier => "Blue Cross Blue Shield MA",
        :plan_selection => "Sole Source",
        :single_plan_hios_id => dental_products[0].hios_id,
        :employee_only_rt_contribution => "50",
        :employee_only_rt_premium => "574.03",
        :employee_and_spouse_rt_offered => "True",
        :employee_and_spouse_rt_contribution => "50",
        :employee_and_spouse_rt_premium => "1148.05",
        :employee_and_one_or_more_dependents_rt_offered => "True",
        :employee_and_one_or_more_dependents_rt_contribution => "50",
        :employee_and_one_or_more_dependents_rt_premium => "1061.95",
        :family_rt_offered => "True",
        :family_rt_contribution => "50",
        :family_rt_premium => "1635.97"
    }
    }

    let(:append_attributes) { {
        default_plan_year_start: benefit_application.effective_period.min,
        plan_year_end: benefit_application.effective_period.max,
        mid_year_conversion: false,
        orginal_plan_year_begin_date: benefit_application.effective_period.min
    }
    }

    subject { Importers::Mhc::ConversionEmployerDentalInitializer.new(record_attrs.merge(append_attributes)) }

    it "should create a dental benefit application" do
      subject.save


    end


  end
end