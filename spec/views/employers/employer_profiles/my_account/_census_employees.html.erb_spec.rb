require "rails_helper"

RSpec.describe "employers/employer_profiles/my_account/_census_employees.html.erb" do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:census_employee) { FactoryGirl.create(:census_employee) }
  # Person necessary for has_role? to work
  let(:user_with_hbx_staff_role) { FactoryGirl.create(:user, :with_family, :with_hbx_staff_role) }
  let(:user_with_employer_role) {FactoryGirl.create(:user, :with_family, :employer_staff) }
  let(:hbx_staff_permission) { FactoryGirl.create(:permission, :hbx_staff) }
  let(:non_hbx_employer_profile_policy) { EmployerProfilePolicy.new(user_with_employer_role, employer_profile) }
  let(:hbx_employer_profile_policy) { EmployerProfilePolicy.new(user_with_hbx_staff_role, employer_profile) }

  before :each do
    allow(employer_profile).to receive(:census_employees).and_return [census_employee]
    assign(:employer_profile, employer_profile)
    assign(:available_employee_names, "employee_names")
    assign(:census_employees, [])
    allow(view).to receive(:generate_checkbook_urls_employers_employer_profile_path).and_return('/')
    allow(view).to receive(:current_user).and_return(user_with_employer_role)
    allow(view).to receive(:policy_helper).and_return(non_hbx_employer_profile_policy)
    render "employers/employer_profiles/my_account/census_employees"
  end

  it "should display title" do
    expect(rendered).to match(/Employee Roster/)
  end

  it "should not have waive filter option" do
    expect(rendered).not_to have_selector("input[value='waived']")
  end

  it "should have the link of add employee" do
    expect(rendered).to have_selector("a", text: 'Add New Employee')
  end

  it "should have tab of cobra" do
    expect(rendered).to match(/COBRA Continuation/)
    expect(rendered).to have_selector('input#cobra')
  end

  context 'Terminate All Employees button' do
    before do
      employer_profile.stub_chain('active_plan_year.start_on').and_return(Date.today)
      employer_profile.stub_chain('active_plan_year.end_on').and_return(Date.today + 1.year)
    end

    it 'should display for HBX admin' do
      allow(view).to receive(:current_user).and_return(user_with_hbx_staff_role)
      allow(view).to receive(:policy_helper).and_return(hbx_employer_profile_policy)
      user_with_hbx_staff_role.stub_chain('person.hbx_staff_role.permission').and_return(hbx_staff_permission)
      render "employers/employer_profiles/my_account/census_employees"
      expect(rendered).to match(/Terminate Employee Roster Enrollments/)
    end

    it 'should not display for employer' do
      allow(view).to receive(:current_user).and_return(user_with_employer_role)
      render "employers/employer_profiles/my_account/census_employees"
      expect(rendered).to_not match(/Terminate Employee Roster Enrollments/)
    end
  end
end