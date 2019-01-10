require 'rails_helper'

RSpec.describe ShopEmployerNotices::InitialEmployerEligibilityNotice, dbclean: :around_each  do
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let(:person){ create :person}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Initial Employer SHOP Approval Notice',
                            :notice_template => 'notices/shop_employer_notices/2_initial_employer_approval_notice',
                            :notice_builder => 'ShopEmployerNotices::InitialEmployerEligibilityNotice',
                            :event_name => 'initial_employer_approval',
                            :mpi_indicator => 'SHOP_D002',
                            :title => "Employer Approval Notice"})
                          }
  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}
  let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization)     { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
  let!(:model_instance) { FactoryGirl.create(:benefit_sponsors_benefit_application,
                                             :with_benefit_package,
                                             :benefit_sponsorship => benefit_sponsorship,
                                             :aasm_state => 'enrollment_open',
                                             :effective_period =>  start_on..(start_on + 1.year) - 1.day
  )}
  let(:benefit_application_schedular) { BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new }

  before do
    allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
    @employer_notice = ShopEmployerNotices::InitialEmployerEligibilityNotice.new(employer_profile, valid_params)
  end

  describe "New" do

    context "valid params" do
      it "should initialze" do
        expect{ShopEmployerNotices::InitialEmployerEligibilityNotice.new(employer_profile, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployerNotices::InitialEmployerEligibilityNotice.new(employer_profile, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do

    before do
      @employer_notice.build
    end

    it "should build notice with person full_name" do
      expect(@employer_notice.notice.primary_fullname).to eq person.full_name.titleize
    end

    it "should build notice with legal_name" do
      expect(@employer_notice.notice.employer_name).to eq employer_profile.organization.legal_name.titleize
    end

    it "should build notice with hbx_id" do
      expect(@employer_notice.notice.primary_identifier).to eq employer_profile.hbx_id
    end
  end

  describe "append_data" do

    before do
      plan_year = employer_profile.plan_years.first
      @employer_notice.append_data
    end

    it "should append PlanYear start_on date" do
      expect(@employer_notice.notice.plan_year.start_on).to eq model_instance.start_on
    end

    it "should append PlanYear open_enrollment_start_on date" do
      expect(@employer_notice.notice.plan_year.open_enrollment_start_on).to eq model_instance.open_enrollment_start_on
    end

    it "should append PlanYear open_enrollment_end_on date" do
      expect(@employer_notice.notice.plan_year.open_enrollment_end_on).to eq model_instance.open_enrollment_end_on
    end

    it "should append PlanYear due_date" do
      due_date = benefit_application_schedular.calculate_open_enrollment_date(model_instance.start_on)[:binder_payment_due_date]
      expect(@employer_notice.notice.plan_year.binder_payment_due_date).to eq due_date
    end
  end

  describe "#ApplicationEventKind" do

    it "find with event_name" do
      expect(@employer_notice.event_name).to eq application_event.event_name
    end

    it "render 2_initial_employer_approval_notice" do
      expect(@employer_notice.template).to eq application_event.notice_template
    end

    it "match mpi_indicator" do
      expect(@employer_notice.mpi_indicator).to eq application_event.mpi_indicator
    end
  end
end