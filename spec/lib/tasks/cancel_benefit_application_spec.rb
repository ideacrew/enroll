require 'rails_helper'
require 'rake'

describe 'cancel employer benefit application & enrollments', :dbclean => :around_each do
  describe 'migrations:cancel_benefit_application' do

    let(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:benefit_market)      { site.benefit_markets.first }
    let(:current_effective_date)  { TimeKeeper.date_of_record }
    let!(:benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                            benefit_market: benefit_market,
                                            title: "SHOP Benefits for #{current_effective_date.year}",
                                            application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
                                          }
    let(:organization)        { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)    { organization.employer_profile }
    let(:benefit_sponsorship) { employer_profile.add_benefit_sponsorship }
    let(:employee_role)     { FactoryGirl.create(:employee_role)}
    let!(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, aasm_state: :enrollment_open) }
    let!(:product_package_kind) { :single_issuer }
    let!(:product_package) { benefit_market_catalog.product_packages.where(package_kind: product_package_kind).first }
    let!(:benefit_package) { FactoryGirl.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application, product_package: product_package) }
    let(:family) { FactoryGirl.build(:family, :with_primary_family_member)}
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: organization.employer_profile, employee_role_id: employee_role.id) }
    let(:enrollment)     { FactoryGirl.build(:hbx_enrollment, household: family.active_household, sponsored_benefit_package_id: benefit_package.id, employee_role_id: employee_role.id)}
    let!(:fein)          {organization.fein}

    before do
      enrollment.update_attributes(aasm_state:'coverage_selected')
      employee_role.update_attributes(census_employee_id: census_employee.id)
    end

    context 'should cancel benefit application & enrollment', :dbclean => :around_each do
      before do
        load File.expand_path("#{Rails.root}/lib/tasks/migrations/cancel_benefit_application.rake", __FILE__)
        Rake::Task.define_task(:environment)
        Rake::Task["migrations:cancel_employer_incorrect_renewal"].reenable
        Rake::Task["migrations:cancel_employer_incorrect_renewal"].invoke(fein)
        benefit_application.reload
        enrollment.reload
      end
      it "should update application aasm_state" do
        expect(benefit_application.aasm_state).to eq :canceled
      end

      it "should update enrollment aasm_state" do
        expect(enrollment.aasm_state).to eq "coverage_canceled"
      end
    end
  end
end
