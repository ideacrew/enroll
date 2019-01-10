require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ShopEmployerNotices::RenewalEmployerIneligibilityNotice, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application" do
    let(:renewal_state)                { :enrollment_closed }
  end

  let(:person){ create :person}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Renewal Group Ineligible to Obtain Coverage',
                            :notice_template => 'notices/shop_employer_notices/19_renewal_employer_ineligibility_notice',
                            :notice_builder => 'ShopEmployerNotices::RenewalEmployerIneligibilityNotice',
                            :event_name => 'renewal_employer_ineligibility_notice',
                            :mpi_indicator => 'MPI_SHOP19',
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
        expect{ShopEmployerNotices::RenewalEmployerIneligibilityNotice.new(abc_profile, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployerNotices::RenewalEmployerIneligibilityNotice.new(abc_profile, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(abc_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::RenewalEmployerIneligibilityNotice.new(abc_profile, valid_parmas)
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
      TimeKeeper.set_date_of_record_unprotected!(renewal_application.open_enrollment_end_on.next_day)
      renewal_application.deny_enrollment_eligiblity!
      @employer_notice = ShopEmployerNotices::RenewalEmployerIneligibilityNotice.new(abc_profile, valid_parmas)
      @employer_notice.append_data
    end

    after do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    it "should return renewal plan year start on" do
      expect(@employer_notice.notice.plan_year.start_on).to eq renewal_application.start_on
    end

    it "should return open enrollment end on date" do
      expect(@employer_notice.notice.plan_year.open_enrollment_end_on).to eq renewal_application.open_enrollment_end_on
    end

    it "should return active plan year end on" do
      expect(@employer_notice.notice.plan_year.end_on).to eq predecessor_application.end_on
    end

    it "should return plan year warnings" do
      if renewal_application.start_on.yday != 1
        expect(@employer_notice.notice.plan_year.warnings).to eq ["At least two-thirds of your eligible employees enrolled in your group health coverage or waive due to having other coverage.", "One non-owner employee enrolled in health coverage"]
      else
        expect(@employer_notice.notice.plan_year.warnings).to eq []
      end
    end
  end

end
