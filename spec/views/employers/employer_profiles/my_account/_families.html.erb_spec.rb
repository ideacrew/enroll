require "rails_helper"

RSpec.describe "employers/employer_profiles/my_account/_families.html.erb" do

  let(:family_1){
    double("Family",
      is_active: true,
      renewal_consent_through_year: 2015
      )
  }

  let(:person_1){
    double("Person1",
      id: "test",
      first_name: "john",
      last_name: "doe",
      ssn: "888888888",
      dob: 25.years.ago
      )
  }

  let(:person_2){
    double("Person2",
      first_name: "john2",
      last_name: "doe2",
      )
  }

  let(:employer_profile){
    double("EmployerProfile",
      id: "test"
      )
  }

  let(:employee_role_1){
    double("EmployeeRole1",
      person: person_1
      )
  }
  let(:employee_role_2){
    double("EmployeeRole2",
    person: person_2
    )
  }

  let(:employee_roles){ [employee_role_1, employee_role_2] }

  before :each do
    assign(:employees, employee_roles)
    assign(:employer_profile, employer_profile)
    allow(person_1).to receive(:has_active_employee_role?).and_return(true)
    allow(person_1).to receive(:primary_family).and_return(family_1)
    allow(employee_role_1).to receive(:employer_profile).and_return(employer_profile)
    allow(person_2).to receive(:has_active_employee_role?).and_return(false)
    render "employers/employer_profiles/my_account/families"
  end

  it "should display active employee role" do
    expect(rendered).to match(/#{person_1.first_name}/)
    expect(rendered).to match(/#{person_1.last_name}/)
    expect(rendered).to match(/#{format_date person_1.dob}/)
    expect(rendered).to match(/#{number_to_obscured_ssn person_1.ssn}/)
    expect(rendered).to have_link("Consumer", href:"/employers/employer_profiles/test/consumer_override?person_id=test")
  end

  it "should not display inactive employee role" do
    expect(rendered).not_to match(/#{person_2.first_name}/)
    expect(rendered).not_to match(/#{person_2.last_name}/)
  end

end
