require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ShopEmployerNotices::RenewalEmployerReminderToPublishPlanyear, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application"

  let(:person){ FactoryGirl.create :person}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Renewal Employer reminder to publish plan year.',
                            :notice_template => 'notices/shop_employer_notices/renewal_employer_reminder_to_publish_plan_year',
                            :notice_builder => 'ShopEmployerNotices::RenewalEmployerReminderToPublishPlanyear',
                            :event_name => 'renewal_employer_final_reminder_to_publish_plan_year',
                            :mpi_indicator => 'MPI_SHOP29',
                            :title => "Group Renewal – Reminder to Publish"})
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
        expect{ShopEmployerNotices::RenewalEmployerReminderToPublishPlanyear.new(abc_profile, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployerNotices::RenewalEmployerReminderToPublishPlanyear.new(abc_profile, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(abc_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::RenewalEmployerReminderToPublishPlanyear.new(abc_profile, valid_parmas)
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
      @employer_notice = ShopEmployerNotices::RenewalEmployerReminderToPublishPlanyear.new(abc_profile, valid_parmas)
    end
    it "should append data" do
      @employer_notice.append_data
      expect(@employer_notice.notice.plan_year.start_on).to eq renewal_application.start_on
    end
  end

end