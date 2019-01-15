require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ShopEmployeeNotices::OpenEnrollmentNoticeForAutoRenewal, :dbclean => :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application"

  let(:person) {FactoryGirl.create(:person)}
  let(:family){ FactoryGirl.create(:family, :with_primary_family_member, person: person) }
  let(:household){ family.active_household }
  let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: benefit_package ) }
  let(:employee_role) { FactoryGirl.create(:employee_role, person: person, employer_profile: abc_profile) }
  let(:benefit_group_assignment) { census_employee.renewal_benefit_group_assignment }
  let(:hbx_enrollment_member) { FactoryGirl.build(:hbx_enrollment_member, is_subscriber:true,  applicant_id: family.family_members.first.id, coverage_start_on: (TimeKeeper.date_of_record).beginning_of_month, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, :with_product, sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id,
                                            household: household,
                                            hbx_enrollment_members: [hbx_enrollment_member],
                                            coverage_kind: "health",
                                            external_enrollment: false,
                                            rating_area_id: rating_area.id )
  }
  let(:product) {hbx_enrollment.product}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Renewal Open Enrollment available for Employee',
                            :notice_template => 'notices/shop_employee_notices/8a_renewal_open_enrollment_notice_for_employee',
                            :notice_builder => 'ShopEmployeeNotices::OpenEnrollmentNoticeForAutoRenewal',
                            :mpi_indicator => 'MPI_SHOP8A',
                            :event_name => 'employee_open_enrollment_auto_renewal',
                            :title => "Your Health Plan Open Enrollment Period has Begun"})
  }

  let(:valid_parmas) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}

  describe "New" do
    before do
      @employee_notice = ShopEmployeeNotices::OpenEnrollmentNoticeForAutoRenewal.new(census_employee, valid_parmas)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::OpenEnrollmentNoticeForAutoRenewal.new(census_employee, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployeeNotices::OpenEnrollmentNoticeForAutoRenewal.new(census_employee, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      @employee_notice = ShopEmployeeNotices::OpenEnrollmentNoticeForAutoRenewal.new(census_employee, valid_parmas)
    end
    it "should build notice with all necessory info" do
      @employee_notice.build
      expect(@employee_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employee_notice.notice.employer_name).to eq abc_profile.organization.legal_name.titleize
    end
  end

  describe "append data" do
    before do
      allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([hbx_enrollment])
      allow(hbx_enrollment).to receive(:total_employee_cost).and_return("0.00")
      @employee_notice = ShopEmployeeNotices::OpenEnrollmentNoticeForAutoRenewal.new(census_employee, valid_parmas)
    end

    it "should append data" do
      @employee_notice.append_data
      expect(@employee_notice.notice.plan_year.start_on).to eq renewal_application.start_on
      expect(@employee_notice.notice.plan_year.open_enrollment_end_on).to eq renewal_application.open_enrollment_end_on
      expect(@employee_notice.notice.plan.plan_name).to eq product.name
      total_employee_cost = ActiveSupport::NumberHelper.number_to_currency(hbx_enrollment.total_employee_cost)
      expect(@employee_notice.notice.enrollment.employee_cost).to eq total_employee_cost
      expect(@employee_notice.notice.enrollment.enrollees.first.full_name).to eq hbx_enrollment.hbx_enrollment_members.first.person.full_name
    end
  end
end
