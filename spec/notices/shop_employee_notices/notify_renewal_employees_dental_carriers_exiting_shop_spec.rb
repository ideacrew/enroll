require 'rails_helper'

RSpec.describe ShopEmployeeNotices::NotifyRenewalEmployeesDentalCarriersExitingShop, :dbclean => :after_each do
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month}
  let(:open_enrollment_start_on) {TimeKeeper.date_of_record.beginning_of_month}
  let(:current_effective_date)  { TimeKeeper.date_of_record }

  let(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :dc) }
  let(:organization)     { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, site: site) }
  let(:employer_profile)    { organization.employer_profile }
  let(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
  let(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application,
                              :with_benefit_package,
                              :benefit_sponsorship => benefit_sponsorship,
                              :effective_period => start_on..start_on.next_year.prev_day, 
                              :aasm_state => 'active',
                              :open_enrollment_period => open_enrollment_start_on..open_enrollment_start_on+20.days
  )}

  let(:person)       { FactoryGirl.create(:person, :with_family) }
  let(:family)       { person.primary_family }
  let(:employee_role) { FactoryGirl.create(:benefit_sponsors_employee_role, person: person, employer_profile: employer_profile)}
  let(:census_employee)  { FactoryGirl.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: employer_profile, employee_role_id: employee_role.id, first_name: person.first_name, last_name: person.last_name ) }
  
  let!(:hbx_enrollment) { 
    hbx_enrollment = FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, :with_product, 
                        household: family.active_household, 
                        aasm_state: "coverage_selected",
                        rating_area_id: benefit_application.recorded_rating_area_id,
                        sponsored_benefit_id: benefit_application.benefit_packages.first.health_sponsored_benefit.id,
                        sponsored_benefit_package_id:benefit_application.benefit_packages.first.id,
                        benefit_sponsorship_id:benefit_application.benefit_sponsorship.id, 
                        employee_role_id: employee_role.id
                        ) 
    hbx_enrollment.benefit_sponsorship = benefit_sponsorship
    hbx_enrollment.save!
    hbx_enrollment
  }
  let(:product) {hbx_enrollment.product}
  let(:issuer_profile) { FactoryGirl.create(:benefit_sponsors_organizations_issuer_profile)}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Renewal EEs Dental Carriers are Exiting SHOP market notice',
                            :notice_template => 'notices/shop_employee_notices/notify_renewal_employees_dental_carriers_exiting_shop',
                            :notice_builder => 'ShopEmployeeNotices::NotifyRenewalEmployeesDentalCarriersExitingShop',
                            :event_name => 'notify_renewal_employees_dental_carriers_exiting_shop',
                            :mpi_indicator => 'SHOP_D092',
                            :title => "Dental Carrier Exit from DC Health Link’s Small Business Marketplace"})
  }

  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :options => {
      :event_object => hbx_enrollment
      }
  }}

  before do
    allow(product).to receive(:issuer_profile).and_return(issuer_profile)
    @employee_notice = ShopEmployeeNotices::NotifyRenewalEmployeesDentalCarriersExitingShop.new(census_employee, valid_params)
  end

  describe "New" do
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::NotifyRenewalEmployeesDentalCarriersExitingShop.new(census_employee, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployeeNotices::NotifyRenewalEmployeesDentalCarriersExitingShop.new(census_employee, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do 
      @employee_notice.build
    end

    it "should build notice with primary full name" do
      expect(@employee_notice.notice.primary_fullname).to eq person.full_name.titleize
    end
    
    #ToDo Fix in DC new model after udpdating the notice builder
    it "should build notice with organization name" do
      expect(@employee_notice.notice.employer_name).to eq employer_profile.organization.legal_name.titleize
    end
  end

  describe "append data" do
    before do
      @employee_notice.append_data
    end

    it "should append plan name" do
      expect(@employee_notice.notice.plan.plan_name).to eq product.name
    end

    it "should append plan year start_on date" do
      expect(@employee_notice.notice.plan.coverage_start_on).to eq hbx_enrollment.sponsored_benefit_package.benefit_application.start_on.to_date
    end

    it "should append plan year end_on date" do
      expect(@employee_notice.notice.plan.coverage_end_on).to eq hbx_enrollment.sponsored_benefit_package.benefit_application.end_on.to_date
    end

    it "should append carrier name" do
      expect(@employee_notice.notice.plan.plan_carrier).to eq product.issuer_profile.organization.legal_name
    end
  end

  describe "should render template" do
    it "render notify_renewal_employees_dental_carriers_exiting_shop" do
      expect(@employee_notice.template).to eq "notices/shop_employee_notices/notify_renewal_employees_dental_carriers_exiting_shop"
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
