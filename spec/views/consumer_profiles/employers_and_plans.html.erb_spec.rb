require 'rails_helper'

RSpec.describe "consumer_profiles/_employers_and_plans.html.erb" do
  let(:person) {FactoryGirl.create(:person)}
  let(:user) {FactoryGirl.create(:user, :person=>person)}
  let(:employee_role) { FactoryGirl.create(:employee_role) }
  let(:hbx_enrollment) { double }

  before :each do
    allow(employee_role).to receive(:effective_on).and_return(Date.new(2015,8,8))
    assign(:employee_role, employee_role)
    assign(:hbx_enrollments, [hbx_enrollment])
    assign(:person, person)
    sign_in user
    render template: "consumer_profiles/_employers_and_plans.html.erb"
  end

  it "should show the link of shop for plan" do
  	expect(rendered).to match(/Shop for plans/) 
    expect(rendered).to have_selector("a[href='/group_selection/new?change_plan=change&employee_role_id=#{employee_role.id}&person_id=#{person.id}']")
  end
end
