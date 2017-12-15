require 'rails_helper'

RSpec.describe "events/enrollment_event.haml.erb" do
  let(:person) { FactoryGirl.create(:person)}
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member,person: person) }
  let(:primary_applicant) { family.primary_applicant }
  let(:plan) { FactoryGirl.build(:plan) }
  let(:census_employee) { FactoryGirl.build(:census_employee, :benefit_group_assignments => [FactoryGirl.build(:benefit_group_assignment)]) }
  let(:employee_role) { FactoryGirl.build(:employee_role, census_employee: census_employee) }
  let(:benefit_group_assignment) { employee_role.census_employee.benefit_group_assignments.first }
  let(:benefit_group) { benefit_group_assignment.benefit_group }
  let(:hbx_enrollment) {  FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, household: family.active_household) }
  let(:hbx_enrollment_member) { HbxEnrollmentMember.create(applicant_id: primary_applicant.id, hbx_enrollment: hbx_enrollment, is_subscriber: primary_applicant.is_primary_applicant, coverage_start_on: hbx_enrollment.effective_on, eligibility_date: hbx_enrollment.effective_on) }

  before :each do
    allow(hbx_enrollment).to receive(:broker_agency_account).and_return(nil)
    allow(hbx_enrollment).to receive(:benefit_group_assignment).and_return(benefit_group_assignment)
    allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
    hbx_enrollment.hbx_enrollment_members << hbx_enrollment_member
  end

  it "generates an enrollment event CV" do 
    render :template => "events/enrollment_event", :locals=> {hbx_enrollment: hbx_enrollment}
    expect(rendered).to include("<market>urn:openhbx:terms:v1:aca_marketplace#shop</market>")
    expect(rendered).to include("<affected_members>")
    expect(rendered).to include("<enrollment_event_body>")
    expect(rendered).to include("<policy>")
  end
end