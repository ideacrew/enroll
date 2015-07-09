require "rails_helper"

RSpec.describe "employers/employer_profiles/my_account/_home_tab.html.erb" do
  context "employer profile dashboard" do

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

    def employer_profile
      instance_double(
        "EmployerProfile",
        legal_name: "My silly name",
        organization: new_organization,
        fein: "098111000",
        entity_kind: "my entity kind",
        broker_agency_profile: new_broker_agency_profile
        )
    end

    def new_broker_agency_profile
      instance_double(
        "BrokerAgencyProfile",
        legal_name: "my broker legal name",
        primary_broker_role: broker_role
        )
    end

    def broker_role
      instance_double(
        "BrokerRole",
        person: new_person
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

    let(:new_office_locations){[office_location,office_location]}

    before :each do
      assign :employer_profile, employer_profile
      controller.request.path_parameters[:id] = "11111111"
      render partial: "employers/employer_profiles/my_account/home_tab.html.erb"
    end

    it "should display dashboard info of employer" do
      expect(rendered).to match(/#{employer_profile.legal_name}/)
      # expect(rendered).to match(/#{number_to_obscured_fein(employer_profile.fein)}/)
      expect(rendered).to match(/#{employer_profile.entity_kind}/i)
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
  end
end

