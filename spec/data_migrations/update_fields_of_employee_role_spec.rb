require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_fields_of_employee_role")

describe UpdateFieldsOfEmployeeRole, dbclean: :after_each do

  let(:given_task_name) { "update_fields_of_employee_role" }
  subject { UpdateFieldsOfEmployeeRole.new(given_task_name, double(:current_scope => nil)) }

  before :each do
    allow(ENV).to receive(:[]).with("census_employee_id").and_return(nil)
    allow(ENV).to receive(:[]).with("organization_fein").and_return(nil)
  end

  describe "given a task name", dbclean: :after_each do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update employer_profile_id for an employee_role", dbclean: :after_each do
    let(:office_location)                 { FactoryBot.build(:office_location, :primary) }
    let!(:old_organization)               { FactoryBot.create(:organization, office_locations: [office_location]) }
    let!(:old_employer_profile)           { FactoryBot.create(:employer_profile, organization: old_organization) }
    let!(:person)                         { FactoryBot.create(:person) }
    let!(:employee_role)                  { FactoryBot.create(:employee_role, person: person, employer_profile_id: old_employer_profile.id) }

    let!(:rating_area)                    { FactoryBot.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)                   { FactoryBot.create_default :benefit_markets_locations_service_area }
    let!(:site)                           { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:organization)                   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let!(:employer_profile)               { organization.employer_profile }

    context "for successfull update" do
      before :each do
        allow(ENV).to receive(:[]).with("organization_fein").and_return(organization.fein.to_s)
        allow(ENV).to receive(:[]).with("employee_role_id").and_return(employee_role.id.to_s)
        allow(ENV).to receive(:[]).with("action").and_return("update_benefit_sponsors_employer_profile_id")
      end

      it "should update employer_profile id for employee_role" do
        expect(employee_role.employer_profile_id.to_s).to eq old_employer_profile.id.to_s
        subject.migrate
        employee_role.reload
        expect(employee_role.benefit_sponsors_employer_profile_id.to_s).to eq employer_profile.id.to_s
      end
    end

    context "for no update" do
      before :each do
        allow(ENV).to receive(:[]).with("organization_fein").and_return(old_organization.fein.to_s)
        allow(ENV).to receive(:[]).with("employee_role_id").and_return(employee_role.id.to_s)
        allow(ENV).to receive(:[]).with("action").and_return("update_benefit_sponsors_employer_profile_id")
      end

      it "should exit as it cannot find new_model's organization for given fein" do
        expect(employee_role.employer_profile_id.to_s).to eq old_employer_profile.id.to_s
        subject.migrate
        expect(employee_role.employer_profile_id.to_s).to eq old_employer_profile.id.to_s
      end
    end
  end


  describe "update census employee id for an employee_role", dbclean: :after_each do
    let(:office_location)                 { FactoryBot.build(:office_location, :primary) }
    let(:old_organization)               { FactoryBot.create(:organization, office_locations: [office_location]) }
    let(:old_employer_profile)           { FactoryBot.create(:employer_profile, organization: old_organization) }
    let(:old_census_record)              { CensusEmployee.create(first_name:"Eddie", last_name:"Vedder", gender:"male", dob: "1964-10-23".to_date, employer_profile_id: old_employer_profile.id, hired_on: "2015-04-01".to_date, ssn: "112212221") }
    let(:person)                         { FactoryBot.create(:person) }
    let(:employee_role)                  { FactoryBot.create(:employee_role, person: person, employer_profile_id: old_employer_profile.id, census_employee_id: old_census_record.id) }

    let(:rating_area)                    { FactoryBot.create_default :benefit_markets_locations_rating_area }
    let(:service_area)                   { FactoryBot.create_default :benefit_markets_locations_service_area }
    let(:site)                           { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:organization)                   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)               { organization.employer_profile }
    let(:census_employee)                 { FactoryBot.create(:benefit_sponsors_census_employee, employer_profile: employer_profile, benefit_sponsorship: benefit_sponsorship, employee_role_id: employee_role.id) }
    let(:benefit_sponsorship)             { employer_profile.add_benefit_sponsorship }
    let(:benefit_market)                  { site.benefit_markets.first }

    let(:benefit_sponsorship) do
      FactoryBot.create(
        :benefit_sponsors_benefit_sponsorship,
        organization: organization,
        profile_id: organization.profiles.first.id,
        benefit_market: site.benefit_markets[0])
    end

    context "for successfull update" do
      before :each do
        allow(ENV).to receive(:[]).with("organization_fein").and_return(organization.fein.to_s)
        allow(ENV).to receive(:[]).with("employee_role_id").and_return(employee_role.id.to_s)
        allow(ENV).to receive(:[]).with("action").and_return("update_census_employee_id")
      end

      it "should update census employee id for an employee_role" do
        expect(employee_role.census_employee_id.to_s).not_to eq census_employee.id.to_s
        subject.migrate
        employee_role.reload
        expect(employee_role.census_employee_id.to_s).to eq census_employee.id.to_s
      end
    end

    context "for no update" do
      before :each do
        allow(ENV).to receive(:[]).with("organization_fein").and_return(organization.fein.to_s)
        allow(ENV).to receive(:[]).with("employee_role_id").and_return("21221212112")
        allow(ENV).to receive(:[]).with("action").and_return("update_census_employee_id")
      end

      it "should exit and should not change the census_employee_id" do
        subject.migrate
        expect(employee_role.census_employee_id.to_s).not_to eq census_employee.id.to_s
      end
    end
  end

  describe "#update_with_given_census_employee_id" do
    let(:census_employee) { FactoryBot.create(:census_employee)}
    let(:person) { FactoryBot.create(:person, :with_employee_role)}
    let(:employee_role) { person.employee_roles.first }

    context "should update census_employee_id by using employee_role" do
      before :each do
        allow(ENV).to receive(:[]).with("census_employee_id").and_return(census_employee.id.to_s)
        allow(ENV).to receive(:[]).with("employee_role_id").and_return(employee_role.id.to_s)
        allow(ENV).to receive(:[]).with("action").and_return("update_with_given_census_employee_id")
      end

      it "should update census_employee_id by using employee_role" do
        expect(employee_role.census_employee_id.to_s).not_to eq census_employee.id.to_s
        subject.migrate
        employee_role.reload
        expect(employee_role.census_employee_id.to_s).to eq census_employee.id.to_s
      end
    end
  end
end
