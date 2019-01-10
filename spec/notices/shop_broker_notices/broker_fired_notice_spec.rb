require 'rails_helper'

RSpec.describe ShopBrokerNotices::BrokerFiredNotice, dbclean: :after_each do
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, :person => person)}
  let(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let(:organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let(:employer_profile) { organization.employer_profile }
  let(:broker_agency_organization1) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, legal_name: 'First Legal Name', site: site) }
  let(:broker_agency_profile) { broker_agency_organization1.broker_agency_profile}
  let(:broker_agency_account) { create(:benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: broker_agency_profile) }
  let(:broker_role) { FactoryGirl.create(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person) }

  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Broker Fired',
                            :notice_template => 'notices/shop_broker_notices/broker_fired_notice',
                            :notice_builder => 'ShopBrokerNotices::BrokerFiredNotice',
                            :event_name => 'broker_fired_confirmation_to_broker',
                            :mpi_indicator => 'SHOP_D051)',
                            :title => "You have been removed as a Broker"})
                          }
  let(:valid_parmas) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :options => {:event_object => employer_profile}
  }}

  before do
    allow(employer_profile).to receive_message_chain("broker_agency_accounts.unscoped.last").and_return(broker_agency_account)
    allow(broker_agency_profile).to receive(:primary_broker_role).and_return(broker_role)
  end

  describe "New" do
    context "valid params" do
      it "should initialze" do
        expect{ShopBrokerNotices::BrokerFiredNotice.new(broker_role, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopBrokerNotices::BrokerFiredNotice.new(broker_role, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @broker_notice = ShopBrokerNotices::BrokerFiredNotice.new(broker_role, valid_parmas)
      @broker_notice.build
    end
    it "should return broker_agency legal name" do
      expect(@broker_notice.notice.broker_agency).to eq broker_agency_profile.legal_name.titleize
    end
    it "should return assignment end date" do
      expect(@broker_notice.notice.termination_date).to eq broker_agency_account.end_on
    end
  end

  describe "Render template & Generate PDF" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @broker_notice = ShopBrokerNotices::BrokerFiredNotice.new(broker_role, valid_parmas)
    end
    it "should render broker_fired_notice" do
      expect(@broker_notice.template).to eq "notices/shop_broker_notices/broker_fired_notice"
    end
    it "should generate pdf" do
      @broker_notice.build
      @broker_notice.generate_pdf_notice
      file = @broker_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end
