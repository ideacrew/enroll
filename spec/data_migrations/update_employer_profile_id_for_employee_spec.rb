require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_employer_profile_id_for_employee")

describe UpdateEmployerProfileIdForEmployee, dbclean: :after_each do

  let(:given_task_name) { "update_employer_profile_id_for_employee" }
  subject { UpdateEmployerProfileIdForEmployee.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name", dbclean: :after_each do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update employer_profile_id for an employee_role", dbclean: :after_each do
    let(:office_location)                 { FactoryGirl.build(:office_location, :primary) }
    let!(:old_organization)               { FactoryGirl.create(:organization, office_locations: [office_location]) }
    let!(:old_employer_profile)           { FactoryGirl.create(:employer_profile, organization: old_organization) }
    let!(:person)                         { FactoryGirl.create(:person) }
    let!(:employee_role)                  { FactoryGirl.create(:employee_role, person: person, benefit_sponsors_employer_profile_id: old_employer_profile.id) }

    let!(:rating_area)                    { FactoryGirl.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)                   { FactoryGirl.create_default :benefit_markets_locations_service_area }
    let!(:site)                           { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:organization)                   { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let!(:employer_profile)               { organization.employer_profile }

    context "for successfull update" do
      before :each do
        allow(ENV).to receive(:[]).with("organization_fein").and_return(organization.fein.to_s)
        allow(ENV).to receive(:[]).with("employee_role_id").and_return(employee_role.id.to_s)
      end

      it "should update employer_profile id for employee_role" do
        expect(employee_role.benefit_sponsors_employer_profile_id.to_s).to eq old_employer_profile.id.to_s
        subject.migrate
        employee_role.reload
        expect(employee_role.benefit_sponsors_employer_profile_id.to_s).to eq employer_profile.id.to_s
      end
    end

    context "for no update" do
      before :each do
        allow(ENV).to receive(:[]).with("organization_fein").and_return(old_organization.fein.to_s)
        allow(ENV).to receive(:[]).with("employee_role_id").and_return(employee_role.id.to_s)
      end

      it "should exit as it cannot find new_model's organization for given fein" do
        expect(employee_role.benefit_sponsors_employer_profile_id.to_s).to eq old_employer_profile.id.to_s
        subject.migrate
        expect(employee_role.benefit_sponsors_employer_profile_id.to_s).to eq old_employer_profile.id.to_s
      end
    end
  end
end
