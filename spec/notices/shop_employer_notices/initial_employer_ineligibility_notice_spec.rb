require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ShopEmployerNotices::InitialEmployerIneligibilityNotice, dbclean: :after_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application" do
    let(:aasm_state)                { :enrollment_closed }
  end

  let(:person){ FactoryGirl.create :person}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Initial Employer ineligible to obtain coverage.',
                            :notice_template => 'notices/shop_employer_notices/initial_employer_ineligibility_notice',
                            :notice_builder => 'ShopEmployerNotices::InitialEmployerIneligibilityNotice',
                            :event_name => 'initial_employer_ineligibility_notice',
                            :mpi_indicator => 'SHOP_D020',
                            :title => "Group Ineligible to Obtain Coverage"})
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
        expect{ShopEmployerNotices::InitialEmployerIneligibilityNotice.new(abc_profile, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployerNotices::InitialEmployerIneligibilityNotice.new(abc_profile, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(abc_profile).to receive_message_chain("staff_roles.first").and_return(person)
      TimeKeeper.set_date_of_record_unprotected!(initial_application.open_enrollment_end_on.next_day)
      initial_application.deny_enrollment_eligiblity!
      @employer_notice = ShopEmployerNotices::InitialEmployerIneligibilityNotice.new(abc_profile, valid_parmas)
    end

    after do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    it "should build notice with all necessary info" do
      @employer_notice.build
      expect(@employer_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employer_notice.notice.employer_name).to eq abc_profile.organization.legal_name.titleize
      expect(@employer_notice.notice.primary_identifier).to eq abc_profile.hbx_id
    end
  end

  describe "append_data" do
    before do
      allow(abc_profile).to receive_message_chain("staff_roles.first").and_return(person)
      TimeKeeper.set_date_of_record_unprotected!(initial_application.open_enrollment_end_on.next_day)
      initial_application.deny_enrollment_eligiblity!
      @employer_notice = ShopEmployerNotices::InitialEmployerIneligibilityNotice.new(abc_profile, valid_parmas)
      @employer_notice.append_data
    end

    after do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    it "should return plan year start on" do
      expect(@employer_notice.notice.plan_year.start_on).to eq initial_application.start_on
    end

    it "should return open enrollment end on" do
      expect(@employer_notice.notice.plan_year.open_enrollment_end_on).to eq initial_application.open_enrollment_end_on
    end

    it "should return planyear warnings" do
      if initial_application.start_on.yday != 1
        expect(@employer_notice.notice.plan_year.warnings).to eq ["At least two-thirds of your eligible employees enrolled in your group health coverage or waive due to having other coverage.", "One non-owner employee enrolled in health coverage"]
      else
        expect(@employer_notice.notice.plan_year.warnings).to eq []
      end
    end

    it "should render initial_employer_ineligibility_notice" do
     expect(@employer_notice.template).to eq "notices/shop_employer_notices/initial_employer_ineligibility_notice"
    end
 
    it "should generate pdf" do
      @employer_notice.build
      @employer_notice.append_data
      @employer_notice.generate_pdf_notice
      expect(File.exist?(@employer_notice.notice_path)).to be true
    end
  end

end
