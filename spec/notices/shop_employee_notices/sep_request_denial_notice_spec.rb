require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ShopEmployeeNotices::SepRequestDenialNotice, :dbclean => :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application"

  let(:hbx_profile)   { FactoryGirl.create(:benefit_sponsors_organizations_hbx_profile, organization: abc_organization) }
  let(:renewal_bcp) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, start_on: TimeKeeper.date_of_record.beginning_of_year, end_on: TimeKeeper.date_of_record.end_of_year, open_enrollment_start_on: Date.new(TimeKeeper.date_of_record.next_year.year,11,1), open_enrollment_end_on: Date.new((TimeKeeper.date_of_record+2.years).year,1,31)) }
  let(:bcp) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, plan_year: TimeKeeper.date_of_record.beginning_of_year.next_year,  start_on: TimeKeeper.date_of_record.beginning_of_year.next_year, end_on: TimeKeeper.date_of_record.end_of_year.next_year, open_enrollment_start_on: Date.new(TimeKeeper.date_of_record.year,11,1), open_enrollment_end_on: Date.new(TimeKeeper.date_of_record.next_year.year,1,31)) }
  let(:person) {FactoryGirl.create(:person)}
  let(:family){ FactoryGirl.create(:family, :with_primary_family_member, person: person) }
  let(:household){ family.active_household }
  let!(:census_employee) { FactoryGirl.create(:census_employee, :with_active_assignment, employee_role_id: employee_role.id, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: benefit_package ) }
  let!(:employee_role) { FactoryGirl.create(:employee_role, person: person, employer_profile: abc_profile) }
  let(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }
  let(:hbx_enrollment_member) { FactoryGirl.build(:hbx_enrollment_member, is_subscriber:true,  applicant_id: family.family_members.first.id, coverage_start_on: (TimeKeeper.date_of_record).beginning_of_month, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, :with_product, sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id,
                                            household: household,
                                            hbx_enrollment_members: [hbx_enrollment_member],
                                            coverage_kind: "health",
                                            external_enrollment: false,
                                            rating_area_id: rating_area.id )
  }

  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Denial of SEP Requested by EE outside of allowable time frame',
                            :notice_template => 'notices/shop_employee_notices/sep_request_denial_notice',
                            :notice_builder => 'ShopEmployeeNotices::SepRequestDenialNotice',
                            :mpi_indicator => 'SHOP_D035',
                            :event_name => 'employee_notice_for_sep_denial',
                            :title => "Special Enrollment Period Denial"})
  }
  let(:qle_on) { TimeKeeper.date_of_record + 10.days }
  let(:end_on) { qle_on + 30.days }
  let(:qle_title) { "Had a baby" }

  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :options=> {:qle_event_on=> qle_on, :qle_title=> qle_title}
  }}

  before do
    @employee_notice = ShopEmployeeNotices::SepRequestDenialNotice.new(census_employee, valid_params)
  end

  describe "New" do
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
    it "should build notice with all necessory info" do
      @employee_notice.build
      expect(@employee_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employee_notice.notice.employer_name).to eq abc_profile.organization.legal_name.titleize
    end
  end

  describe "append data" do
    let(:special_enrollment_period) {[double("SpecialEnrollmentPeriod")]}
    let(:sep1) {family.special_enrollment_periods.new}
    let(:sep2) {family.special_enrollment_periods.new}
    let(:order) {[sep1,sep2]}

    it "should append data" do
      @employee_notice.append_data
      expect(@employee_notice.notice.sep.start_on).to eq qle_on
      expect(@employee_notice.notice.sep.end_on).to eq end_on
      expect(@employee_notice.notice.sep.title).to eq qle_title
      expect(@employee_notice.notice.plan_year.start_on).to eq renewal_application.start_on+1.year
    end
  end
end
