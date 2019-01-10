require 'rails_helper'

RSpec.describe ShopEmployerNotices::ZeroEmployeesOnRoster, dbclean: :around_each  do
  let(:person){ create :person}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Zero Employees on Roster',
                            :notice_template => 'notices/shop_employer_notices/notice_for_employers_with_zero_employees_on_roster',
                            :notice_builder => 'ShopEmployerNotices::ZeroEmployeesOnRoster',
                            :event_name => 'zero_employees_on_roster',
                            :mpi_indicator => 'MPI_SHOP6',
                            :title => "Action Needed – Add all Eligible Employees to your Roster"})
                        }
  let(:valid_parmas) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}
  let(:model_event)  { "renewal_application_autosubmitted" }
  let(:notice_event) { "zero_employees_on_roster_notice" }
  let!(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 2.months}
  let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization)     { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
  let!(:model_instance) { FactoryGirl.create(:benefit_sponsors_benefit_application,
                                             :with_benefit_package,
                                             :benefit_sponsorship => benefit_sponsorship,
                                             :aasm_state => 'draft',
                                             :effective_period =>  start_on..(start_on + 1.year) - 1.day
  )}
  let(:benefit_application_schedular) { BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new }

  describe "New" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployerNotices::ZeroEmployeesOnRoster.new(employer_profile, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployerNotices::ZeroEmployeesOnRoster.new(employer_profile, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::ZeroEmployeesOnRoster.new(employer_profile, valid_parmas)
    end
    it "should build notice with all necessary info" do
      @employer_notice.build
      expect(@employer_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employer_notice.notice.employer_name).to eq employer_profile.organization.legal_name.titleize
      expect(@employer_notice.notice.primary_identifier).to eq employer_profile.hbx_id
    end
  end

  describe "append_data" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::ZeroEmployeesOnRoster.new(employer_profile, valid_parmas)
    end
    it "should append necessary information" do
      plan_year = employer_profile.show_plan_year
      due_date = benefit_application_schedular.calculate_open_enrollment_date(plan_year.start_on)[:binder_payment_due_date]
      @employer_notice.append_data
      expect(@employer_notice.notice.plan_year.open_enrollment_end_on).to eq plan_year.open_enrollment_end_on
      expect(@employer_notice.notice.plan_year.binder_payment_due_date).to eq due_date
   end
  end
end