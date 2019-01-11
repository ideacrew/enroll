require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application"

  let(:person){ FactoryGirl.create :person}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Employer Annual Renewal - Denial of Eligibility',
                            :notice_template => 'notices/shop_employer_notices/employer_renewal_eligibility_denial_notice',
                            :notice_builder => 'ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice',
                            :event_name => 'employer_renewal_eligibility_denial_notice',
                            :mpi_indicator => 'SHOP_D005',
                            :title => "Employer Annual Renewal - Denial of Eligibility"})
                          }
  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :organization => abc_organization
  }}

  describe "New" do
    before do
      allow(abc_profile).to receive_message_chain("staff_roles.first").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice.new(abc_profile, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice.new(abc_profile, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(abc_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice.new(abc_profile, valid_params)
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
      renewal_application.submit_for_review!
      @employer_notice = ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice.new(abc_profile, valid_params)
    end

    it "should append necessary" do
      @employer_notice.append_data
      expect(@employer_notice.notice.plan_year.start_on).to eq renewal_application.start_on
      expect(@employer_notice.notice.plan_year.end_on).to eq predecessor_application.end_on
      expect(@employer_notice.notice.plan_year.warnings).to eq ["primary location is outside washington dc"]
    end
  end
end
