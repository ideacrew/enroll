require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "activate_benefit_group_assignment")

describe ActivateBenefitGroupAssignment do

  let(:given_task_name) { "activate_benefit_group_assignment" }
  subject { ActivateBenefitGroupAssignment.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "activate benefit group assignment for particular census employee" do

    # let!(:benefit_group1)     { FactoryGirl.create(:benefit_group, plan_year: plan_year)}
    # let!(:benefit_group2)     { FactoryGirl.create(:benefit_group, plan_year: plan_year)}
    # let!(:plan_year)         { FactoryGirl.create(:plan_year, aasm_state: "draft", employer_profile: employer_profile) }
    # let(:employer_profile)  { FactoryGirl.create(:employer_profile) }
    let!(:census_employee) { FactoryGirl.create(:census_employee,ssn:"123456789")}

    let!(:benefit_group_assignment1)  { FactoryGirl.create(:benefit_group_assignment, is_active: false, census_employee: census_employee)}
    let!(:benefit_group_assignment2)  { FactoryGirl.create(:benefit_group_assignment, is_active: false, census_employee: census_employee)}
    before(:each) do
      allow(ENV).to receive(:[]).with("ce_ssn").and_return(census_employee.ssn)
      allow(ENV).to receive(:[]).with("bga_id").and_return(benefit_group_assignment1.id)
      allow(ENV).to receive(:[]).with("action").and_return("update_benefit_group_assignment_for_ce")
    end

    context "activate_benefit_group_assignmentfor_particular_census_employee", dbclean: :after_each do
      it "should activate_related_benefit_group_assignment_for_particular_census_employee" do
        expect(benefit_group_assignment1.is_active).to eq false
        subject.migrate
        census_employee.reload
        expect(census_employee.benefit_group_assignments.where(id:benefit_group_assignment1.id).first.is_active).to eq true
      end
      it "should_not activate_unrelated_benefit_group_assignment_for_particular_census_employee" do
        expect(benefit_group_assignment2.is_active).to eq false
        subject.migrate
        census_employee.reload
        expect(census_employee.benefit_group_assignments.where(id:benefit_group_assignment2.id).first.is_active).to eq false
      end
    end
  end

    describe "activate benefit group assignment for all the census employees for an employer" do
    let(:employer_organization)  { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:site)  { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:current_effective_date)  { TimeKeeper.date_of_record }
    let!(:benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                            benefit_market: benefit_market,
                                            title: "SHOP Benefits for #{current_effective_date.year}",
                                            application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
                                          }
    let(:benefit_market)      { site.benefit_markets.first }
    let!(:product_package) { benefit_market_catalog.product_packages.first }
    let!(:rating_area)   { FactoryGirl.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)  { FactoryGirl.create_default :benefit_markets_locations_service_area }
    let(:organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let!(:employer_attestation)     { BenefitSponsors::Documents::EmployerAttestation.new(aasm_state: "approved") }
    let(:benefit_sponsorship) do
      FactoryGirl.create(
        :benefit_sponsors_benefit_sponsorship,
        :with_rating_area,
        :with_service_areas,
        supplied_rating_area: rating_area,
        service_area_list: [service_area],
        organization: organization,
        profile_id: organization.profiles.first.id,
        benefit_market: site.benefit_markets[0],
        employer_attestation: employer_attestation)
    end

    let(:start_on)  { current_effective_date.prev_month }
    let(:effective_period)  { start_on..start_on.next_year.prev_day }
    let!(:benefit_application) {
      application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, effective_period: effective_period, aasm_state: :canceled)
      application.benefit_sponsor_catalog.save!
      application
    }
    let!(:benefit_application_1) {
      application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, benefit_sponsorship: benefit_sponsorship, effective_period: effective_period, aasm_state: :enrolling)
      application.benefit_sponsor_catalog.save!
      application
    }

    let!(:benefit_package) { FactoryGirl.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application, product_package: product_package) }
    let!(:benefit_package_1) { FactoryGirl.create(:benefit_sponsors_benefit_packages_benefit_package, benefit_application: benefit_application_1, product_package: product_package) }
    let(:benefit_group_assignment) {FactoryGirl.build(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_package)}
    let(:benefit_group_assignment_1) {FactoryGirl.build(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_package_1, is_active: "false")}
    let(:employee_role) { FactoryGirl.create(:benefit_sponsors_employee_role, person: person, employer_profile: benefit_sponsorship.profile, census_employee_id: census_employee.id) }
    let(:census_employee) { FactoryGirl.create(:benefit_sponsors_census_employee,
      employer_profile: benefit_sponsorship.profile,
      benefit_sponsorship: benefit_sponsorship,
      benefit_group_assignments: [benefit_group_assignment,benefit_group_assignment_1]
    )}
    let(:person) { FactoryGirl.create(:person) }
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}

    let(:employee_role_1) { FactoryGirl.create(:benefit_sponsors_employee_role, person: person_1, employer_profile: benefit_sponsorship.profile, census_employee_id: census_employee_1.id) }
    let(:census_employee_1) { FactoryGirl.create(:benefit_sponsors_census_employee,
      employer_profile: benefit_sponsorship.profile,
      benefit_sponsorship: benefit_sponsorship,
      benefit_group_assignments: [benefit_group_assignment,benefit_group_assignment_1]
    )}
    let(:person_1) { FactoryGirl.create(:person) }
    let!(:family_1) { FactoryGirl.create(:family, :with_primary_family_member, person: person_1)}


    before(:each) do
      allow(ENV).to receive(:[]).with("benefit_package_id").and_return(benefit_package_1.id.to_s)
      allow(ENV).to receive(:[]).with("action").and_return("update_benefit_group_assignment_for_er")
    end

    context "activate_benefit_group_assignment for all the employees", dbclean: :after_each do
      it "should activate_related_benefit_group_assignment_for_all_the_census_employees" do
        expect(benefit_group_assignment_1.is_active).to eq false
        subject.migrate
        census_employee.reload
        census_employee_1.reload
        expect(census_employee.benefit_group_assignments.where(id:benefit_group_assignment_1.id).first.is_active).to eq true
        expect(census_employee_1.benefit_group_assignments.where(id:benefit_group_assignment_1.id).first.is_active).to eq true
      end
      it "should_not activate_unrelated_benefit_group_assignment_for_all_the_census_employees" do
        census_employee.benefit_group_assignments.where(id:benefit_group_assignment.id).first.update_attributes!(is_active:"false")
        census_employee_1.benefit_group_assignments.where(id:benefit_group_assignment.id).first.update_attributes!(is_active:"false")
        subject.migrate
        census_employee.reload
        census_employee_1.reload
        expect(census_employee.benefit_group_assignments.where(id:benefit_group_assignment.id).first.is_active).to eq false
        expect(census_employee_1.benefit_group_assignments.where(id:benefit_group_assignment.id).first.is_active).to eq false
      end
    end
  end
end

