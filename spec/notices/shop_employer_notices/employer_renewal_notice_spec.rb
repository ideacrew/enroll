require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ShopEmployerNotices::EmployerRenewalNotice, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application"
  let(:person){ FactoryGirl.create :person}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Conversion, Group Renewal Available',
                            :notice_template => 'notices/shop_employer_notices/6_conversion_group_renewal_notice',
                            :notice_builder => 'ShopEmployerNotices::EmployerRenewalNotice',
                            :event_name => 'group_renewal_5',
                            :mpi_indicator => 'MPI_SHOP6',
                            :title => "Welcome to DC Health Link, Group Renewal Available"})
  }
  let(:issuer_profile){
    double("IssuerProfile",
      legal_name: "BLUE CHOICE Health Plan"
      )
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
        expect{ShopEmployerNotices::EmployerRenewalNotice.new(abc_profile, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployerNotices::EmployerRenewalNotice.new(abc_profile, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(abc_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::EmployerRenewalNotice.new(abc_profile, valid_parmas)
    end
    it "should build notice with all necessory info" do
      @employer_notice.build
      expect(@employer_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employer_notice.notice.employer_name).to eq abc_profile.organization.legal_name.titleize
      expect(@employer_notice.notice.primary_identifier).to eq abc_profile.hbx_id
    end
  end

  describe "append data" do
    before do
      allow(abc_profile).to receive_message_chain("staff_roles.first").and_return(person)
      allow(renewal_application).to receive_message_chain("benefit_packages.first.reference_plan.carrier_profile").and_return(issuer_profile)
      @employer_notice = ShopEmployerNotices::EmployerRenewalNotice.new(abc_profile, valid_parmas)
    end
    it "should append data" do
      @employer_notice.append_data
      expect(@employer_notice.notice.plan_year.start_on).to eq renewal_application.start_on
      expect(@employer_notice.notice.plan_year.open_enrollment_end_on).to eq renewal_application.open_enrollment_end_on
      expect(@employer_notice.notice.plan_year.carrier_name).to eq renewal_application.benefit_packages.first.reference_plan.carrier_profile.legal_name
    end
  end

end