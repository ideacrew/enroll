require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_enrollment_details")

describe ChangeEnrollmentDetails do

  let(:given_task_name) { "update_benefit_group_assignment_details" }
  subject { UpdateBenefitGroupAssignmentDetails.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing enrollment attributes" do

    let(:start_date) { TimeKeeper.date_of_record}
    let(:end_date) { TimeKeeper.date_of_record - 5.days}
    let(:current_effective_date)  { TimeKeeper.date_of_record }
    let(:start_on)  { current_effective_date.prev_month }
    let(:effective_period)  { start_on..start_on.next_year.prev_day }
    let!(:site) { create(:benefit_sponsors_site,:with_benefit_market, :with_benefit_market_catalog_and_product_packages, :as_hbx_profile, :cca) }
    let!(:org) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile) { org.employer_profile }
    let!(:rating_area) { FactoryGirl.create_default :benefit_markets_locations_rating_area }
    let!(:service_area) { FactoryGirl.create_default :benefit_markets_locations_service_area }
    let(:benefit_sponsorship) { employer_profile.add_benefit_sponsorship }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:benefit_market) { site.benefit_markets.first }
    let(:benefit_market_catalog) { benefit_market.benefit_market_catalogs.first }
    let!(:product_package) { benefit_market_catalog.product_packages.where(package_kind: :single_issuer).first }
    let!(:benefit_package) { FactoryGirl.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application, product_package: product_package) }
    let!(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, aasm_state: :active) }
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, sponsored_benefit_package_id: benefit_package.id, household: family.active_household)}
    let!(:benefit_group_assignment) {FactoryGirl.create(:benefit_group_assignment, census_employee: census_employee,  benefit_package: benefit_package, hbx_enrollment: hbx_enrollment, start_on: benefit_application.start_on, aasm_state: "coverage_selected") }
    let(:census_employee) { FactoryGirl.create(:benefit_sponsors_census_employee, employer_profile: employer_profile, benefit_sponsorship: benefit_sponsorship) }

    before(:each) do
      benefit_application.update_attributes(effective_period: effective_period)
      allow(ENV).to receive(:[]).with("ce_id").and_return(census_employee.id.to_s)
      allow(ENV).to receive(:[]).with("bga_id").and_return(benefit_group_assignment.id)
      allow(ENV).to receive(:[]).with("new_state").and_return "coverage_void"
      allow(ENV).to receive(:[]).with("action").and_return "change_aasm_state"
    end

    it "should change the aasm state" do

      subject.migrate
      benefit_group_assignment.reload
      expect(benefit_group_assignment.aasm_state).to eq "coverage_void"
    end
  end
end
