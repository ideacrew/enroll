require 'rails_helper'

Rspec.describe "events/enrollment_event.haml.erb" do 
  let(:plan) { FactoryGirl.build(:plan) }
  let(:census_employee) { FactoryGirl.build(:census_employee, :benefit_group_assignments => [FactoryGirl.build(:benefit_group_assignment)]) }
  let(:employee_role) { FactoryGirl.build(:employee_role, census_employee: census_employee) }
  let(:benefit_group_assignment) { employee_role.census_employee.benefit_group_assignments.first }
  let(:benefit_group) { benefit_group_assignment.benefit_group }
  let(:hbx_enrollment) {  HbxEnrollment.new(plan:plan, employee_role: employee_role, created_at: Time.now) }

  before :each do
    allow(hbx_enrollment).to receive(:broker_agency_account).and_return(nil)
    allow(hbx_enrollment).to receive(:benefit_group_assignment).and_return(benefit_group_assignment)
    allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
  end

  it "generates an enrollment event CV" do 
    render :template => "events/enrollment_event", :locals=> {hbx_enrollment: hbx_enrollment}
    expect(rendered).to include("<market>urn:openhbx:terms:v1:aca_marketplace#shop</market>")
    expect(rendered).to include("<affected_members>")
    expect(rendered).to include("<enrollment_event_body>")
    expect(rendered).to include("<policy>")
  end
end