require 'rails_helper'

RSpec.describe ShopEmployeeNotices::SepRequestDenialNotice, :dbclean => :after_each do

  let!(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
  let!(:benefit_sponsorship) { FactoryGirl.create(:benefit_sponsorship, hbx_profile: hbx_profile) }
  let!(:benefit_coverage_period_2018) { FactoryGirl.create(:benefit_coverage_period, start_on: Date.new(2018,1,1), end_on: Date.new(2018,12,31), open_enrollment_start_on: Date.new(2017,11,1), open_enrollment_end_on: Date.new(2018,1,31), title: "Individual Market Benefits 2018", benefit_sponsorship: benefit_sponsorship) }
  let!(:benefit_coverage_period_2019) {FactoryGirl.create(:benefit_coverage_period, open_enrollment_start_on: Date.new(2018,11,01), open_enrollment_end_on: Date.new(2019,1,31),start_on: Date.new(2019,1,1),end_on: Date.new(2019,12,31),benefit_sponsorship: benefit_sponsorship)}

  let(:plan) { FactoryGirl.create(:plan) }
  let(:plan2) { FactoryGirl.create(:plan) }
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let!(:person){ create :person}
  let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: TimeKeeper.date_of_record.beginning_of_year, :aasm_state => 'published' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: active_benefit_group, census_employee: census_employee) }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, benefit_group_assignment: benefit_group_assignment, household: family.active_household, effective_on: TimeKeeper.date_of_record.beginning_of_month + 2.month, aasm_state: 'coverage_termination_pending')}
  let(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
  let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
  let(:renewal_plan) { FactoryGirl.create(:plan)}
  let(:plan) { FactoryGirl.create(:plan, :with_premium_tables, :renewal_plan_id => renewal_plan.id)}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Denial of SEP Requested by EE outside of allowable time frame',
                            :notice_template => 'notices/shop_employee_notices/sep_request_denial_notice',
                            :notice_builder => 'ShopEmployeeNotices::SepRequestDenialNotice',
                            :mpi_indicator => 'SHOP_D035',
                            :event_name => 'sep_request_denial_notice',
                            :title => "Special Enrollment Period Denial"})
                          }

    let(:valid_params) {{
        :subject => application_event.title,
        :mpi_indicator => application_event.mpi_indicator,
        :event_name => application_event.event_name,
        :template => application_event.notice_template,
        :options=>{:qle_reported_date=> TimeKeeper.date_of_record + 10.days,:qle_title=>"Had a baby"}
    }}

  describe "New" do
    before do
      @employee_notice = ShopEmployeeNotices::SepRequestDenialNotice.new(census_employee, valid_params)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::SepRequestDenialNotice.new(census_employee, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployeeNotices::SepRequestDenialNotice.new(census_employee, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      @employee_notice = ShopEmployeeNotices::SepRequestDenialNotice.new(census_employee, valid_params)
    end
    it "should build notice with all necessory info" do

      @employee_notice.build
      expect(@employee_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employee_notice.notice.employer_name).to eq employer_profile.organization.legal_name
    end
  end

  describe "append data" do

    let(:qle_reported_date) { valid_params[:options][:qle_reported_date]}
    let(:title) { valid_params[:options][:qle_title]}

    before do
      @employee_notice = ShopEmployeeNotices::SepRequestDenialNotice.new(census_employee, valid_params)
    end

    it "should append data" do
      @employee_notice.append_data
      expect(@employee_notice.notice.sep.start_on).to eq qle_reported_date
      expect(@employee_notice.notice.sep.end_on).to eq qle_reported_date+30.days
      expect(@employee_notice.notice.sep.title).to eq title
      expect(@employee_notice.notice.plan_year.start_on).to eq plan_year.start_on+1.year
    end
  end

end