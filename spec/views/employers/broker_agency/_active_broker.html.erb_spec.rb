require 'rails_helper'

describe "employers/broker_agency/_active_broker.html.erb" do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:broker_agency_account) {
    double(writing_agent: double(
      person: FactoryGirl.create(:person),
      phone: '3015551212',
      email: double('email', address: 'stuff@dc.gov')
    ))
  }
  let(:broker_agency_accounts) { [broker_agency_account] }
  let(:broker_agency_profile) { double(id: 1, legal_name: "legal name", organization: organization, entity_kind: "entity?", accept_new_clients?: true, working_hours?: true, languages: "English") }
  let(:organization) { double(office_locations: [office_location], primary_office_location: primary_office_location, fein: 203893782)}
  let(:office_location) { double(primary_office_location: primary_office_location )}
  let(:primary_office_location) { double(address: address)}
  let(:address) {double(address_1: "somewhere", city: "Washington", state: "DC", zip: 20002)}
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, person: person) }


  before :each do
    sign_in user
    assign(:employer_profile, employer_profile)
    assign(:broker_agency_accounts, broker_agency_accounts)
  end

  context "terminate time" do
    it "set date to current day" do
      allow(broker_agency_account).to receive(:start_on).and_return(TimeKeeper.date_of_record)

      allow(employer_profile).to receive(:broker_agency_profile).and_return(broker_agency_profile)

      link = employers_employer_profile_broker_agency_terminate_path(employer_profile.id, employer_profile.broker_agency_profile.id, termination_date: TimeKeeper.date_of_record, direct_terminate: true)
      render "employers/broker_agency/active_broker", direct_terminate: true
      expect(rendered).to have_link('Terminate Broker', href: link)
    end

    it "set date to the day before current" do
      allow(broker_agency_account).to receive(:start_on).and_return(TimeKeeper.date_of_record - 10.days)

      allow(employer_profile).to receive(:broker_agency_profile).and_return(broker_agency_profile)

      link = employers_employer_profile_broker_agency_terminate_path(employer_profile.id, employer_profile.broker_agency_profile.id, termination_date: TimeKeeper.date_of_record - 1.day, direct_terminate: true)
      render "employers/broker_agency/active_broker", direct_terminate: true
      expect(rendered).to have_link('Terminate Broker', href: link)
    end
  end

  context "show broker information" do

    before :each do
      allow(employer_profile).to receive(:broker_agency_profile).and_return(broker_agency_profile)
      @employer_profile = employer_profile
      render "employers/broker_agency/active_broker.html.erb"
    end

    it "should show Broker Agency name" do
      expect(rendered).to have_selector('.tt-u', text: broker_agency_profile.legal_name)
    end
    it "show should the Broker email" do
      expect(rendered).to match(/stuff@dc.gov/)
    end
    it "show should the Broker phone" do
      expect(rendered).to match(/3015551212/)
    end

    it "should see button of change broker" do
      expect(rendered).to have_selector('a.btn', text: 'Change Broker')
    end
  end

  context "can_change_broker?" do
    let(:person) { FactoryGirl.create(:person) }
    let(:user) { FactoryGirl.create(:user, person: person) }
    context "without broker" do
      before :each do
        user.roles = [:general_agency_staff]
        sign_in user
        @employer_profile = employer_profile
        render "employers/broker_agency/active_broker.html.erb"
      end

      it "should have disabled button" do
        expect(rendered).to have_selector('a.disabled', text: 'Browse Brokers')
      end
    end

    context "without broker" do
      before :each do
        user.roles = [:general_agency_staff]
        sign_in user
        allow(employer_profile).to receive(:broker_agency_profile).and_return(broker_agency_profile)
        @employer_profile = employer_profile
        render "employers/broker_agency/active_broker.html.erb"
      end

      it "should have disabled button of browser brokers" do
        expect(rendered).to have_selector('a.disabled', text: 'Browse Brokers')
      end

      it "should have disabled button of change broker" do
        expect(rendered).to have_selector('a.disabled', text: 'Change Broker')
      end
    end
  end
end
