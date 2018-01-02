require 'rails_helper'

RSpec.describe ShopEmployeeNotices::EmployeeDependentAgeOffTermination, :dbclean => :after_each do
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let!(:primary_person){ FactoryGirl.create(:person)}
  let!(:person2){ FactoryGirl.create(:person)}
  let!(:person3){ FactoryGirl.create(:person)}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'application_ineligible' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let(:employee_role) {FactoryGirl.create(:employee_role, person: primary_person, employer_profile: employer_profile, benefit_group_id: active_benefit_group.id )}
  let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
  let!(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: active_benefit_group, census_employee: census_employee, start_on: start_on) }
  let(:date) {TimeKeeper.date_of_record}
  let!(:family) {
      family = FactoryGirl.build(:family, :with_primary_family_member, person: primary_person)
      family_member2 = FactoryGirl.create(:family_member, family: family, person: person2)
      family_member3 = FactoryGirl.create(:family_member, family: family, person: person3)
      primary_person.person_relationships << PersonRelationship.new(relative_id: person2.id, kind: "child")
      primary_person.person_relationships << PersonRelationship.new(relative_id: person3.id, kind: "child")
      primary_person.save!
      person2.dob = Date.new(date.year,date.month,date.beginning_of_month.day) - 25.years
      person3.dob = Date.new(date.year,date.month,date.beginning_of_month.day) - 25.years
      family.save!
      family
    }

  let(:enrollment) do
    hbx = FactoryGirl.create(:hbx_enrollment, household: family.active_household, kind: "individual")
    hbx.hbx_enrollment_members << FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, is_subscriber: true)
    hbx.hbx_enrollment_members << FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.where(is_primary_applicant: false).first.id, is_subscriber: false)
    hbx.hbx_enrollment_members << FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.where(is_primary_applicant: false).last.id, is_subscriber: false)
    hbx.save
    hbx
  end

  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Notification to employees regarding their Employer’s ineligibility.',
                            :notice_template => 'notices/shop_employee_notices/employee_dependent_age_off_termination',
                            :notice_builder => 'ShopEmployeeNotices::EmployeeDependentAgeOffTermination',
                            :event_name => 'notify_employee_of_initial_employer_ineligibility',
                            :mpi_indicator => 'MPI_SHOP10047',
                            :title => "Termination of Employer’s Health Coverage Offered through DC Health Link"})
                          }

  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :options => {
        :dep_hbx_ids => [person2.hbx_id, person3.hbx_id]
      }
  }}

  before do
    @employee_notice = ShopEmployeeNotices::EmployeeDependentAgeOffTermination.new(census_employee, valid_params)
    allow(employee_role).to receive(:census_employee).and_return(census_employee)
  end

  describe "New" do

    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::EmployeeDependentAgeOffTermination.new(census_employee, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployeeNotices::EmployeeDependentAgeOffTermination.new(census_employee, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    it "should build notice with employee full_name" do
      @employee_notice.build
      expect(@employee_notice.notice.primary_fullname).to eq census_employee.employee_role.person.full_name
    end

    it "should build notice with employer legal name" do
      @employee_notice.build
      expect(@employee_notice.notice.employer_name).to eq census_employee.employer_profile.legal_name
    end
  end

  describe "append data" do
    before do
      allow(census_employee).to receive(:employee_role).and_return(employee_role)
      allow(TimeKeeper).to receive(:date_of_record).and_return TimeKeeper.date_of_record.beginning_of_month
      census_employee.benefit_group_assignments.first.plan_year.update_attributes(aasm_state: "renewing_enrolled")
    end

    it "should append dependent's hbx_id" do
      enrollment = census_employee.benefit_group_assignments.first.hbx_enrollment
      @employee_notice.append_data
      expect(@employee_notice.notice.enrollment.dependents).to eq family.family_members.where(is_primary_applicant: false).map(&:person).map(&:full_name)
    end

    it "should append boolean data to check is_congress" do
      is_congress = census_employee.employee_role.benefit_group.is_congress
      @employee_notice.append_data
      expect(@employee_notice.notice.enrollment.is_congress).to eq census_employee.employee_role.benefit_group.is_congress
    end

    describe "for generating pdf" do
      it "should generate pdf" do
        @employee_notice.build
        @employee_notice.append_data
        file = @employee_notice.generate_pdf_notice
        expect(File.exist?(file.path)).to be true
      end
    end
  end

  describe "should render template" do
    it "render employee_dependent_age_off_termination" do
      expect(@employee_notice.template).to eq application_event.notice_template
    end
  end
end
