require "rails_helper"

RSpec.describe "employers/employer_profiles/my_account/_home_tab.html.erb" do
  context "employer profile dashboard" do

    let(:start_on){TimeKeeper.date_of_record.beginning_of_year}
    let(:end_on){TimeKeeper.date_of_record.end_of_year}

    def new_organization
      instance_double(
        "Organization",
        office_locations: new_office_locations
      )
    end

    def office_location
      random_value = rand(999_999_999)
      instance_double(
        "OfficeLocation",
        address: new_address(random_value),
        phone: new_phone(random_value),
        )
    end

    def new_address(random_value)
      double(
        "Address",
        kind: "test#{random_value}",
        to_html: "test"
        )
    end

    def new_phone(random_value)
      double(
        "Phone",
        kind: "test#{random_value}"
        )
    end

    def broker_agency_account
      instance_double(
        "BrokerAgencyAccount",
        is_active: true,
        writing_agent: broker_role
        )
    end

    def employer_profile
      instance_double(
        "EmployerProfile",
        legal_name: "My silly name",
        organization: new_organization,
        fein: "098111000",
        entity_kind: "my entity kind",
        broker_agency_profile: new_broker_agency_profile,
        published_plan_year: plan_year
        )
    end

    def new_broker_agency_profile
      instance_double(
        "BrokerAgencyProfile",
        legal_name: "my broker legal name",
        primary_broker_role: broker_role
        )
    end

    def plan_year
      instance_double(
        "PlanYear",
        start_on: start_on,
        end_on: end_on,
        open_enrollment_start_on: PlanYear.calculate_open_enrollment_date(start_on)[:open_enrollment_start_on],
        open_enrollment_end_on: PlanYear.calculate_open_enrollment_date(start_on)[:open_enrollment_end_on],
        eligible_to_enroll_count: 4,
        covered_count: 4,
        waived_count: 4,
        total_enrolled_count: 10,
        employee_participation_percent: 40,
        non_business_owner_enrollment_count: 10,
        hbx_enrollments: [hbx_enrollment],
        aasm_state: 'draft'
        )
    end

    def broker_role
      instance_double(
        "BrokerRole",
        person: new_person,
        npn: 7232323
        )
    end

    def new_person
      random_value = rand(999_999_999)
      instance_double(
        "Person",
        full_name: "my full name",
        phones: [new_phone(random_value)],
        emails: [new_email]
        )
    end

    def new_email
      instance_double(
        "Email",
        address: "test@example.com"
        )
    end

    def hbx_enrollment
      instance_double(
        "HbxEnrollment",
        total_premium: double("total_premium"),
        total_employer_contribution: double("total_employer_contribution"),
        total_employee_cost: double("total_employee_cost")
        )
    end

    let(:new_office_locations){[office_location,office_location]}
    let(:current_plan_year){employer_profile.published_plan_year}

    before :each do
      assign :employer_profile, employer_profile
      assign :hbx_enrollments, [hbx_enrollment]
      assign :current_plan_year, employer_profile.published_plan_year
      assign :participation_minimum, 0
      assign :broker_agency_accounts, [ broker_agency_account ]
      controller.request.path_parameters[:id] = "11111111"
      render partial: "employers/employer_profiles/my_account/home_tab.html.erb"
    end

    it "should display dashboard info of employer" do
      expect(rendered).to match(/#{employer_profile.legal_name}/)
    end

    it "should display office locations" do
      employer_profile.organization.office_locations.each do |off_loc|
        expect(rendered).to match(/#{off_loc.address}/m)
        expect(rendered).to match(/#{off_loc.phone}/m)
      end
    end

    it "should display broker agency name and related information" do
      expect(rendered).to match(/#{employer_profile.broker_agency_profile.legal_name}/)
      expect(rendered).to match(/#{employer_profile.broker_agency_profile.primary_broker_role.person.full_name}/)
    end

    it "should display plan year and related information" do
      expect(rendered).to match(/<dd>#{current_plan_year.start_on.year}<\/dd>/m)
      expect(rendered).to match(/<dd>.*#{format_date current_plan_year.open_enrollment_start_on}.*-.*#{format_date current_plan_year.open_enrollment_end_on}.*<\/dd>/m)
      expect(rendered).to match(/<dd>#{format_date current_plan_year.start_on}<\/dd>/m)
      expect(rendered).to match(/<dd>#{current_plan_year.eligible_to_enroll_count}<\/dd>/m)
      expect(rendered).to match(/<dd>.*#{current_plan_year.total_enrolled_count}.*<\/dd>/m)
      expect(rendered).to match(/<dd>#{boolean_to_human(current_plan_year.non_business_owner_enrollment_count > 0)}<\/dd>/m)
    end
  end
end
