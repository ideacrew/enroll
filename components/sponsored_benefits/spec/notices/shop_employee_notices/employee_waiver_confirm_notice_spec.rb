require 'rails_helper'

RSpec.describe ShopEmployeeNotices::EmployeeWaiverConfirmNotice, :dbclean => :after_each do
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}  
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let!(:person){ create :person}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'enrolling' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let!(:renewal_plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, :aasm_state => 'renewing_draft' ) }
  let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: renewal_plan_year, title: "Benefits #{renewal_plan_year.start_on.year}") }
  let(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
  let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
  let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let!(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group_id: active_benefit_group.id, census_employee: census_employee, start_on: active_benefit_group.start_on) }
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'CONFIRMATION OF ELECTION TO WAIVE COVERAGE',
                            :notice_template => 'notices/shop_employee_notices/employee_waiver_confirmation_notification',
                            :notice_builder => 'ShopEmployeeNotices::EmployeeWaiverConfirmNotice',
                            :mpi_indicator => 'MPI_SHOP8c',
                            :event_name => 'employee_waiver_notice',
                            :title => "CONFIRMATION OF ELECTION TO WAIVE COVERAGE"})
                          }

    let(:valid_parmas) {{
        :subject => application_event.title,
        :mpi_indicator => application_event.mpi_indicator,
        :event_name => application_event.event_name,
        :template => application_event.notice_template
    }}
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, effective_on: TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year, plan: plan)}  
  let(:plan) { FactoryGirl.create(:plan, :with_premium_tables)} 

  describe "New" do
    before do
      @employee_notice = ShopEmployeeNotices::EmployeeWaiverConfirmNotice.new(census_employee, valid_parmas)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::EmployeeWaiverConfirmNotice.new(census_employee, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployeeNotices::EmployeeWaiverConfirmNotice.new(census_employee, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      @employee_notice = ShopEmployeeNotices::EmployeeWaiverConfirmNotice.new(census_employee, valid_parmas)
    end
    it "should build notice with all necessory info" do

      @employee_notice.build
      expect(@employee_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employee_notice.notice.employer_name).to eq employer_profile.organization.legal_name
    end
  end

  describe "append data" do
    before do
      @employee_notice = ShopEmployeeNotices::EmployeeWaiverConfirmNotice.new(census_employee, valid_parmas)
      census_employee.stub_chain(:active_benefit_group_assignment, :hbx_enrollments, :first).and_return(hbx_enrollment)
      hbx_enrollment.update_attributes(updated_at: TimeKeeper.date_of_record)
      #enrollment = census_employee.active_benefit_group_assignment.hbx_enrollments.first
    end
    it "should append data" do
      @employee_notice.append_data
      expect(@employee_notice.notice.enrollment.waived_on).to eq census_employee.active_benefit_group_assignment.hbx_enrollments.first.updated_at
    end
  end

end