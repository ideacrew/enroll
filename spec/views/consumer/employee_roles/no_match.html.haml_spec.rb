require 'rails_helper'

RSpec.describe "consumer/employee_roles/no_match.html.haml" do
  let(:person) {FactoryGirl.create(:person)}

  before :each do
    assign(:person, person)
    render template: "consumer/employee_roles/no_match.html.haml"
  end

  it "should display the employee search page with no match info" do
    expect(rendered).to have_selector('h3', text: 'Personal Information')
    expect(rendered).to have_selector("input[type='text']", count: 6)
    expect(rendered).to have_selector("input[type='radio']", count: 2)

    expect(rendered).to have_selector('strong', text: 'No employer plan found.')
    expect(rendered).to have_selector('div', text: "Check your personal information and try again OR contact DC Health Link's Customer Care Center: 1-855-532-5465.")
  end
end
