require 'rails_helper'

RSpec.describe ShopEmployerNotices::WelcomeEmployerNotice, :dbclean => :after_each do
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let(:person){ create :person}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Welcome Notice sent to Employer',
                            :notice_template => 'notices/shop_employer_notices/0_welcome_notice_employer',
                            :notice_builder => 'ShopEmployerNotices::WelcomeEmployerNotice',
                            :event_name => 'application_created',
                            :mpi_indicator => 'SHOP_M001',
                            :title => "Welcome Notice to Employer"})
                          }

    let(:valid_parmas) {{
        :subject => application_event.title,
        :mpi_indicator => application_event.mpi_indicator,
        :event_name => application_event.event_name,
        :template => application_event.notice_template
    }}

   describe "New" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::WelcomeEmployerNotice.new(employer_profile, valid_parmas)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployerNotices::WelcomeEmployerNotice.new(employer_profile, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployerNotices::WelcomeEmployerNotice.new(employer_profile, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::WelcomeEmployerNotice.new(employer_profile, valid_parmas)
    end
    it "should build notice with all necessory information" do
      @employer_notice.build
      expect(@employer_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employer_notice.notice.employer_name).to eq employer_profile.organization.legal_name
    end
  end
end