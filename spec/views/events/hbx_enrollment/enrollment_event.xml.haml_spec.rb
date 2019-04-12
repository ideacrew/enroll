require 'rails_helper'

RSpec.describe "app/views/events/enrollment_event.xml.haml" do

  let!(:employer_profile) { create(:employer_with_planyear, plan_year_state: 'active')}
  let(:benefit_group) { employer_profile.published_plan_year.benefit_groups.first}
  let!(:census_employees){
    FactoryGirl.create :census_employee, :owner, employer_profile: employer_profile
    employee = FactoryGirl.create :census_employee, employer_profile: employer_profile
    employee.add_benefit_group_assignment benefit_group, benefit_group.start_on }
  let!(:plan) { FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: benefit_group.start_on.year, hios_id: "11111111122302-01", csr_variant_id: "01") }
  let(:ce) { employer_profile.census_employees.non_business_owner.first }
  let!(:family) {
    person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
    employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
    ce.update_attributes({employee_role: employee_role})
    Family.find_or_build_from_employee_role(employee_role)
  }
  let(:person) { family.primary_applicant.person }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment,
                         household: family.active_household,
                         coverage_kind: "health",
                         effective_on: benefit_group.start_on,
                         enrollment_kind: "open_enrollment",
                         kind: "employer_sponsored",
                         benefit_group_id: benefit_group.id,
                         employee_role_id: person.active_employee_roles.first.id,
                         benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
                         plan_id: plan.id) }
  let!(:enrollment_member)  { FactoryGirl.create(:hbx_enrollment_member, is_subscriber: true,
                                                     applicant_id: family.primary_applicant.id, hbx_enrollment: hbx_enrollment,
                                                     eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record) }
  context "enrollment cv for termianted policy" do

    before do
      hbx_enrollment.aasm_state = 'coverage_terminated'
      hbx_enrollment.save
      render :template=>"events/enrollment_event", :locals=>{hbx_enrollment: hbx_enrollment}
      @doc = Nokogiri::XML(rendered)
    end

    it "should include qualifying_reason" do
      expect(@doc.xpath("//x:qualifying_reason", "x"=>"http://openhbx.org/api/terms/1.0").text).to eq "urn:openhbx:terms:v1:benefit_maintenance#termination_of_benefits"
    end
  end
end
