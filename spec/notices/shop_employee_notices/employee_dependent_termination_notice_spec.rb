require 'rails_helper'

RSpec.describe ShopEmployeeNotices::EmployeeDependentTerminationNotice, :dbclean => :after_each do
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:employer_profile){ create :employer_profile, aasm_state: "enrolled"}
  let!(:person){ create :person}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'application_ineligible' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
  let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
  let!(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group_id: active_benefit_group.id, census_employee: census_employee, start_on: start_on) }
  let(:date) {TimeKeeper.date_of_record}
  let(:family) {
    family = FactoryGirl.build(:family, :with_primary_family_member_and_dependent)
    primary_person = family.family_members.where(is_primary_applicant: true).first.person
    other_child_person1 = family.family_members.where(is_primary_applicant: false).first.person
    other_child_person2 = family.family_members.where(is_primary_applicant: false).last.person
    primary_person.person_relationships << PersonRelationship.new(relative_id: other_child_person1.id, kind: "child")
    primary_person.person_relationships << PersonRelationship.new(relative_id: other_child_person2.id, kind: "child")
    primary_person.save
    other_child_person1.dob = Date.new(date.year,date.month,date.beginning_of_month.day) - 26.years
    other_child_person2.dob = Date.new(date.year,date.month,date.beginning_of_month.day) - 26.years
    family.save
    family
  }

  let(:enrollment) do
    hbx = FactoryGirl.create(:hbx_enrollment, household: family.active_household, kind: "employer_sponsored")
    hbx.hbx_enrollment_members << FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, is_subscriber: true)
    hbx.hbx_enrollment_members << FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.where(is_primary_applicant: false).first.id, is_subscriber: false)
    hbx.hbx_enrollment_members << FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.where(is_primary_applicant: false).last.id, is_subscriber: false)
    hbx.save
    hbx
  end

  let(:application_event){ double("ApplicationEventKind",{
                                                            name: 'Notice to EE of DPT Termination due to Age-Off',
                                                            notice_template: 'notices/shop_employee_notices/employee_dependent_termination_notice',
                                                            notice_builder: 'ShopEmployeeNotices::EmployeeDependentTerminationNotice',
                                                            event_name: 'employee_dependent_termination_notice',
                                                            mpi_indicator: 'MPI_SHOPDPTC',
                                                            title: 'Dependent termination due to age off'})
  }

  let(:valid_parmas) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}

  describe "New" do
    before do
      @employee_notice = ShopEmployeeNotices::EmployeeDependentTerminationNotice.new(census_employee, valid_parmas)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::EmployeeDependentTerminationNotice.new(census_employee, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator, :subject, :template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployeeNotices::EmployeeDependentTerminationNotice.new(census_employee, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      @employee_notice = ShopEmployeeNotices::EmployeeDependentTerminationNotice.new(census_employee, valid_parmas)
    end
    it "should build notice with all necessory info" do
      @employee_notice.build
      expect(@employee_notice.notice.primary_fullname).to eq census_employee.employee_role.person.full_name
      expect(@employee_notice.notice.employer_name).to eq census_employee.employer_profile.legal_name
    end
  end

  describe "append data" do
    before do
      allow(benefit_group_assignment).to receive(:hbx_enrollment).and_return enrollment
      @employee_notice = ShopEmployeeNotices::EmployeeDependentTerminationNotice.new(census_employee, valid_parmas)
    end

    it "should append data" do
      enrollment = census_employee.benefit_group_assignments.first.hbx_enrollment
      @employee_notice.append_data
      expect(@employee_notice.notice.enrollment.dependents).to eq family.family_members.where(is_primary_applicant: false).map(&:person).map(&:full_name)
      expect(@employee_notice.notice.enrollment.dependent_dob).to eq date.end_of_month
    end

  end

  describe "Rendering employee dependent termination template and generate pdf" do
    before do
      allow(benefit_group_assignment).to receive(:hbx_enrollment).and_return enrollment
      allow(census_employee.employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employee_notice = ShopEmployeeNotices::EmployeeDependentTerminationNotice.new(census_employee, valid_parmas)
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
    end
    it "should render termination_of_employers_health_coverage" do
      expect(@employee_notice.template).to eq "notices/shop_employee_notices/employee_dependent_termination_notice"
    end
    it "should generate pdf" do
      @employee_notice.build
      @employee_notice.append_data
      file = @employee_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end

end