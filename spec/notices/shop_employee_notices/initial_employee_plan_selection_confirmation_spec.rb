require 'rails_helper'

RSpec.describe ShopEmployeeNotices::InitialEmployeePlanSelectionConfirmation, :dbclean => :after_each do

  let(:application_event){ double("ApplicationEventKind",{
      name: 'Notice to employee after they select a plan Annual Open Enrollment',
      notice_template: 'notices/shop_employee_notices/initial_employee_plan_selection_confirmation',
      notice_builder: 'ShopEmployeeNotices::InitialEmployeePlanSelectionConfirmation',
      mpi_indicator: 'SHOP_D075',
      event_name: 'initial_employee_plan_selection_confirmation',
      title: "Employee Enrollment Confirmation"})
  }
  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}
  let(:model_event)  { "initial_employee_plan_selection_confirmation" }
  let!(:start_on) { TimeKeeper.date_of_record.beginning_of_month }
  let(:current_effective_date)  { TimeKeeper.date_of_record }
  let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization_with_hbx_profile)  { site.owner_organization }
  let!(:organization)     { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
  let!(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application,
                                                  :with_benefit_package,
                                                  dental_sponsored_benefit: true,
                                                  :benefit_sponsorship => benefit_sponsorship,
                                                  :aasm_state => 'enrollment_eligible',
                                                  :effective_period =>  start_on..(start_on + 1.year) - 1.day
  )}
  let!(:benefit_package)  {benefit_application.benefit_packages.first}
  let(:person)       { FactoryGirl.create(:person, :with_family) }
  let(:family)       { person.primary_family }
  let!(:census_employee)  { FactoryGirl.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: employer_profile, active_benefit_group_assignment: benefit_package.id , employee_role_id: employee_role.id) }
  let(:employee_role)     { FactoryGirl.create(:benefit_sponsors_employee_role, employer_profile: employer_profile, person: person) }
  let!(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }
  let(:rate_schedule_date) {TimeKeeper.date_of_record}
  let(:group_enrollment) { double("BenefitSponsors::Enrollments::GroupEnrollment", product_cost_total: 200.00, sponsor_contribution_total: 100 , employee_cost_total: 100 )}
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, :with_product,
                                             household: family.active_household,
                                             aasm_state: "coverage_selected",
                                             effective_on: benefit_application.start_on,
                                             rating_area_id: benefit_application.recorded_rating_area_id,
                                             sponsored_benefit_id: benefit_application.benefit_packages.first.health_sponsored_benefit.id,
                                             sponsored_benefit_package_id:benefit_application.benefit_packages.first.id,
                                             benefit_sponsorship_id:benefit_application.benefit_sponsorship.id,
                                             employee_role_id: employee_role.id,
                                             )}

  let!(:dental_enrollment) {FactoryGirl.create(:hbx_enrollment,
                                               household: census_employee.employee_role.person.primary_family.active_household,
                                               coverage_kind: "dental",
                                               kind: "employer_sponsored",
                                               rating_area_id: benefit_application.recorded_rating_area_id,
                                               sponsored_benefit_id: benefit_application.benefit_packages.first.dental_sponsored_benefit.id,
                                               benefit_sponsorship_id: benefit_sponsorship.id,
                                               sponsored_benefit_package_id: benefit_application.benefit_packages.first.id,
                                               employee_role_id: census_employee.employee_role.id,
                                               benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
                                               aasm_state:  "coverage_selected",
  )
  }


  before do
    @employee_notice = ShopEmployeeNotices::InitialEmployeePlanSelectionConfirmation.new(census_employee, valid_params)
  end

  describe "New" do
    context "valid params" do
      it "should initialze" do
        expect{@employee_notice}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator, :subject, :template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployeeNotices::InitialEmployeePlanSelectionConfirmation.new(census_employee, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    it "should build notice with all necessory info" do
      @employee_notice.build
      expect(@employee_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employee_notice.notice.employer_name).to eq employer_profile.organization.legal_name.titleize
    end
  end

  describe "append data" do
    before do
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
    end
    it "should append data" do
      hbx_enrollment.update_attributes(benefit_group_assignment_id: benefit_group_assignment.id)
      census_employee.active_benefit_group_assignment.hbx_enrollments.first
      @employee_notice.append_data
      expect(@employee_notice.notice.plan_year.start_on).to eq benefit_application.start_on
      expect(@employee_notice.notice.plan.plan_name).to eq hbx_enrollment.plan.name
    end
  end

  describe "render template and generate pdf" do
    before do
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
      allow(census_employee.active_benefit_group_assignment).to receive(:hbx_enrollments).and_return [hbx_enrollment]
      @employee_notice.build
      @employee_notice.append_data
      @employee_notice.generate_pdf_notice
    end

    it "should match mpi_indicator" do
      expect(@employee_notice.mpi_indicator).to eq "SHOP_D075"
    end
    it "should match event" do
      expect(@employee_notice.event_name).to eq "initial_employee_plan_selection_confirmation"
    end
    it "should render initial_employee_plan_selection_confirmation" do
      expect(@employee_notice.template).to eq "notices/shop_employee_notices/initial_employee_plan_selection_confirmation"
    end

    it "should generate pdf" do
      file = @employee_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end