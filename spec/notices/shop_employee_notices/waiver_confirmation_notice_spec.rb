require 'rails_helper'

RSpec.describe ShopEmployeeNotices::WaiverConfirmationNotice, :dbclean => :after_each do
  let!(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let!(:person) { FactoryGirl.create(:person)}
  let!(:person2) { FactoryGirl.create(:person)}
  let!(:family) { 
                family = FactoryGirl.create(:family, :with_primary_family_member, person: person)
                FactoryGirl.create(:family_member, family: family, person: person2)
                person.person_relationships.create!(relative_id: person2.id, kind: "child")
                person.save!
                family.save!
                family }
  let!(:household) { FactoryGirl.build_stubbed(:household, family: family) }
  let!(:hbx_enrollment){FactoryGirl.create(:hbx_enrollment, household:family.active_household, kind: "employer_sponsored", aasm_state: "coverage_terminated")}
  let!(:waived_enrollment){FactoryGirl.create(:hbx_enrollment, household:family.active_household, kind: "employer_sponsored", aasm_state: "inactive")}
  let!(:hbx_enrollment_member2){ FactoryGirl.create(:hbx_enrollment_member, applicant_id: family.family_members.second.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month, is_subscriber: false, hbx_enrollment: hbx_enrollment) }
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let!(:renewal_plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, :aasm_state => 'renewing_draft' ) }
  let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: renewal_plan_year, title: "Benefits #{renewal_plan_year.start_on.year}") }
  let(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
  let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Waiver Confirmation',
                            :notice_template => 'notices/shop_employee_notices/waiver_confirmation_notice',
                            :notice_builder => 'ShopEmployeeNotices::WaiverConfirmationNotice',
                            :event_name => 'waiver_confirmation_notice',
                            :mpi_indicator => 'SHOP_D031',
                            :title => "Confirmation of Election to Waive Coverage"})
                          }

  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :options => {
        :hbx_enrollment => hbx_enrollment.hbx_id.to_s
      }
  }}

  before do
    @employee_notice = ShopEmployeeNotices::WaiverConfirmationNotice.new(census_employee, valid_params)
  end

  describe "New" do
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::WaiverConfirmationNotice.new(census_employee, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployeeNotices::WaiverConfirmationNotice.new(census_employee, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    it "should build notice with all necessory info" do
      @employee_notice.build
      expect(@employee_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employee_notice.notice.employer_name).to eq employer_profile.organization.legal_name
    end
  end

  describe "append data" do

    before do 
      allow(person).to receive_message_chain("primary_family.enrolled_hbx_enrollments").and_return([hbx_enrollment, waived_enrollment])
      allow(person.primary_family).to receive(:household).and_return(household)
      enrollment = census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.reject{|en| en.aasm_state == "inactive"}[-1]
      @employee_notice.append_data
    end

    it "should append enrollment terminated on" do
      expect(@employee_notice.notice.term_enrollment.terminated_on).to eq hbx_enrollment.terminated_on
    end
    it "should append enrollment effective on" do
      expect(@employee_notice.notice.term_enrollment.effective_on).to eq hbx_enrollment.effective_on
    end
    it "should append plan name" do
      expect(@employee_notice.notice.plan.plan_name).to eq hbx_enrollment.plan.name
    end
  end

  describe "render template with event kind" do
    it "render waiver_confirmation_notice" do
      expect(@employee_notice.template).to eq "notices/shop_employee_notices/waiver_confirmation_notice"
    end

    it "should match event name" do
      expect(@employee_notice.event_name).to eq "waiver_confirmation_notice"
    end
    it "should match mpi_indicator" do
      expect(@employee_notice.mpi_indicator).to eq "SHOP_D031"
    end
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