require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ShopEmployerNotices::EmployeeTerminatingCoverage, :dbclean => :after_each do
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
                                            rating_area_id: rating_area.id,
                                            employee_role_id: employee_role.id )
  }
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Notice to employer when employee terminates coverage',
                            :notice_template => 'notices/shop_employer_notices/employee_terminating_coverage',
                            :notice_builder => 'ShopEmployerNotices::EmployeeTerminatingCoverage',
                            :event_name => 'notify_employer_when_employee_terminate_coverage',
                            :mpi_indicator => 'SHOP_D041',
                            :title => "Employee Terminating coverage"})
                          }
  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :options => { :event_object => hbx_enrollment}
  }}

  before do
    allow(abc_profile).to receive_message_chain("staff_roles.first").and_return(person)
    @employer_notice = ShopEmployerNotices::EmployeeTerminatingCoverage.new(abc_profile, valid_params)
  end

  describe "New" do
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployerNotices::EmployeeTerminatingCoverage.new(abc_profile, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployerNotices::EmployeeTerminatingCoverage.new(abc_profile, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    it "should build notice with all necessory info" do
      @employer_notice.build
      expect(@employer_notice.notice.primary_fullname).to eq abc_profile.staff_roles.first.full_name.titleize
      expect(@employer_notice.notice.employer_name).to eq abc_profile.organization.legal_name.titleize
    end
  end

  describe "append data" do
    it "should append data" do
      @employer_notice.append_data
      expect(@employer_notice.notice.enrollment.enrolled_count).to eq hbx_enrollment.humanized_dependent_summary.to_s
      expect(@employer_notice.notice.enrollment.employee_fullname).to eq hbx_enrollment.employee_role.person.full_name.titleize
      expect(@employer_notice.notice.enrollment.terminated_on).to eq hbx_enrollment.terminated_on
    end
  end

  describe "Rendering employee_terminating_coverage notice template and generate pdf" do
    it "should render employee_terminating_coverage notice" do
      expect(@employer_notice.template).to eq application_event.notice_template
    end

    it "should match mpi_indicator" do
      expect(@employer_notice.mpi_indicator).to eq application_event.mpi_indicator
    end

    it "should match event_name" do
      expect(@employer_notice.event_name).to eq application_event.event_name
    end
    it "should generate pdf" do
      @employer_notice.build
      @employer_notice.append_data
      @employer_notice.generate_pdf_notice
      file = @employer_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end
