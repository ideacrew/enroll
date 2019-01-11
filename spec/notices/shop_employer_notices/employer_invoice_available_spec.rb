require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ShopEmployerNotices::EmployerInvoiceAvailable, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let(:person){ FactoryGirl.create :person}
  let(:application_event){ double("ApplicationEventKind",{
      :name =>'Employer monthly invoice available in the account',
      :notice_template => 'notices/shop_employer_notices/employer_invoice_available_notice',
      :notice_builder => 'ShopEmployerNotices::EmployerInvoiceAvailable',
      :event_name => 'employer_invoice_available',
      :mpi_indicator => 'SHOP_D021',
      :title => "Monthly Invoice Available"})
  }
  let(:valid_parmas) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}

  describe "New" do
    before do
      allow(abc_profile).to receive_message_chain("staff_roles.first").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployerNotices::EmployerInvoiceAvailable.new(abc_profile, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployerNotices::EmployerInvoiceAvailable.new(abc_profile, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(abc_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::EmployerInvoiceAvailable.new(abc_profile, valid_parmas)
    end
    it "should build notice with all necessary info" do
      @employer_notice.build
      expect(@employer_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employer_notice.notice.employer_name).to eq abc_profile.organization.legal_name.titleize
      expect(@employer_notice.notice.primary_identifier).to eq abc_profile.hbx_id
    end
  end

  describe "append_data" do
    let(:terminated_employer_plan_year) { BenefitSponsors::BenefitApplications::BenefitApplication.new(aasm_state:"terminated")}
    before do
      allow(abc_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::EmployerInvoiceAvailable.new(abc_profile, valid_parmas)
    end
    it "should append necessary information" do
      scheduler = BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
      due_date = scheduler.calculate_open_enrollment_date(initial_application.start_on)[:binder_payment_due_date]
      @employer_notice.append_data
      expect(@employer_notice.notice.plan_year.start_on).to eq initial_application.start_on
      expect(@employer_notice.notice.plan_year.binder_payment_due_date).to eq due_date
    end

     it "should append information for terminated employer" do
      allow(abc_profile).to receive_message_chain("plan_years.where").and_return([terminated_employer_plan_year])
      @employer_notice.append_data
      expect(@employer_notice.notice.plan_year.start_on).to eq initial_application.start_on
    end
  end

  describe "Render template & Generate PDF" do
    before do
      allow(abc_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::EmployerInvoiceAvailable.new(abc_profile, valid_parmas)
    end
    it "should render renewal_employer_available_notice" do
      expect(@employer_notice.template).to eq "notices/shop_employer_notices/employer_invoice_available_notice"
    end
    it "should generate pdf" do
      @employer_notice.build
      @employer_notice.append_data
      file = @employer_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end