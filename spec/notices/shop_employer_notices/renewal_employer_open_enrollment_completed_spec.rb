require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ShopEmployerNotices::RenewalEmployerOpenEnrollmentCompleted, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application" do
    let(:renewal_state) { :enrollment_eligible }
  end

  let(:person){ FactoryGirl.create :person}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Renewal Employee Open Employee Completed',
                            :notice_template => 'notices/shop_employer_notices/renewal_employer_open_enrollment_completed',
                            :notice_builder => 'ShopEmployerNotices::RenewalEmployerOpenEnrollmentCompleted',
                            :event_name => 'renewal_employer_open_enrollment_completed',
                            :mpi_indicator => 'SHOP_D018',
                            :title => "Group Open Enrollment Successfully Completed"})
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
        expect{ShopEmployerNotices::RenewalEmployerOpenEnrollmentCompleted.new(abc_profile, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployerNotices::RenewalEmployerOpenEnrollmentCompleted.new(abc_profile, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(abc_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::RenewalEmployerOpenEnrollmentCompleted.new(abc_profile, valid_parmas)
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
      @employer_notice = ShopEmployerNotices::RenewalEmployerOpenEnrollmentCompleted.new(abc_profile, valid_parmas)
    end
    it "should append necessary" do
      @employer_notice.append_data
      expect(@employer_notice.notice.plan_year.start_on).to eq renewal_application.start_on
    end

    it "should render renewal_employer_open_enrollment_completed" do
       expect(@employer_notice.template).to eq "notices/shop_employer_notices/renewal_employer_open_enrollment_completed"
      end
   
       it "should generate pdf" do
         @employer_notice.build
         @employer_notice.append_data
         @employer_notice.generate_pdf_notice
         expect(File.exist?(@employer_notice.notice_path)).to be true
      end
  end

end