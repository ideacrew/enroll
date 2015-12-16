require 'rails_helper'

RSpec.describe "insured/employee_roles/match.html.haml" do
  let(:person) {FactoryGirl.create(:person)}
  let(:user) {FactoryGirl.create(:user, :person=>person)}

  before :each do
    assign(:person, person)
    @employee_candidate = Forms::EmployeeCandidate.new(user_id: person.id)
    found_census_employees = @employee_candidate.match_census_employees
    @employment_relationships = Factories::EmploymentRelationshipFactory.build(@employee_candidate, found_census_employees.first)

    sign_in user
    render template: "insured/employee_roles/match.html.haml"
  end

  it "should display the employee search page with no match info" do
    expect(rendered).to have_selector('h1', text: 'Personal Information')
    expect(rendered).to have_selector("input[type='text']", count: 6)
    expect(rendered).to have_selector("input[type='radio']", count: 2)

    # expect(rendered).to have_selector("input[type=submit][value='This is my employer']")
    # expect(rendered).to have_selector('dt', text: 'Employer :')
    # expect(rendered).to have_selector("input", value: 'This is my employer')
    # expect(rendered).to have_selector('div', text: "Check your personal information and try again OR contact DC Health Link's Customer Care Center: 1-855-532-5465.")
  end
end
