require 'rails_helper'

RSpec.describe "insured/families/_employer_panel.html.erb" do
  let(:person) {FactoryGirl.build(:person)}
  let(:employee_role) {FactoryGirl.build(:employee_role)}
  let(:employer_profile) {FactoryGirl.build(:employer_profile)}

  before :each do
    assign(:person, person)
    assign(:employee_role, employee_role)
    render "insured/families/employer_panel"
  end

  it "should have carousel-qles area" do
    expect(rendered).to have_selector('div.employer-panel')
  end

  it "should have employer name" do
    allow(employee_role).to receive(:employer_profile).and_return employer_profile
    expect(rendered).to have_selector('a')
    expect(rendered).to have_content("Your Employer is: #{employer_profile.legal_name}. Click here to shop for Employer-Sponsored coverage.")
  end
end
