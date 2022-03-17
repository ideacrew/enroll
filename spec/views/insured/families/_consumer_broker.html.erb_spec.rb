require 'rails_helper'

RSpec.describe "insured/families/_consumer_broker.html.erb" do
  #render 'consumer_broker', title: nil
  #@person.primary_family.current_broker_agency.broker_agency_profile.legal_name.capitalize



  let(:family1) { FactoryBot.create(:family, :with_primary_family_member)}
  let(:broker_agency_profile){FactoryBot.create(:broker_agency_profile)}
  let(:broker_agency_account){FactoryBot.create(:broker_agency_account,is_active:true)}



  context "shows assignment date" do

    before :each do
      assign :person, family1.person
      assign :family, family1
      assign :broker_agency_account, broker_agency_account
      allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
      person = family1.person
      allow(person).to receive_message_chain("primary_family.current_broker_agency").and_return(broker_agency_account)
      allow(person).to receive_message_chain("primary_family.current_broker_agency.broker_agency_profile.legal_name.capitalize").and_return("BROKER_ORG")
    end

    it "should render the partial" do
      render partial: 'insured/families/consumer_broker.html.erb', locals: { title: nil}
      expect(rendered).to match /Your Broker/
    end

    it "the partial should have Assignment Date" do
      render partial: 'insured/families/consumer_broker.html.erb', locals: { title: nil}
      expect(rendered).to match /Assignment Date/
    end

    it "the partial should display Assignment Date in EST timezone" do
      render partial: 'insured/families/consumer_broker.html.erb', locals: { title: nil}
      date = broker_agency_account.start_on.in_time_zone('Eastern Time (US & Canada)')
      expect(rendered).to have_content(date.strftime("%m/%d/%Y"))
      expect(rendered).to have_content(date.strftime("%-I:%M%p"))
    end
  end
end
