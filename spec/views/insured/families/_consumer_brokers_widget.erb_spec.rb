require 'rails_helper'

RSpec.describe '_consumer_brokers_widget.html.erb' do

  context 'insured home broker widget as consumer with primary family and broker agency accounts' do
    let!(:consumer_role) { FactoryBot.create(:consumer_role) }
    let(:broker_agency_profile){ FactoryBot.create(:broker_agency_profile) }
    let(:broker_agency_account) { FactoryBot.create(:broker_agency_account, broker_agency_profile_id: broker_agency_profile.id) }
    let(:person) { consumer_role.person }
    let!(:family) do
      f = FactoryBot.build(:family)
      f.family_members = [
        FactoryBot.build(:family_member, family: f, person: person, is_primary_applicant: true)
      ]
      f.broker_agency_accounts = [broker_agency_account]
      f.save
      f
    end
    let(:family_member) { family.family_members.last }
    let(:writing_agent) { FactoryBot(:broker_role) }
    let(:formatted_name) {"Turner Agency, Inc"}

    before :each do
      assign(:person, person)
      assign :family_members, [family_member]
      allow(person).to receive(:primary_family).and_return(family)
      allow(family).to receive(:current_broker_agency).and_return(broker_agency_account)
      allow(person).to receive_message_chain('primary_family.current_broker_agency.present?').and_return(true)
      render 'insured/families/consumer_brokers_widget'
    end

    it 'should display broker widget for consumer' do
      expect(rendered).to have_selector('h3')
      expect(rendered).to have_text("Your Broker")
    end

    it 'should display correctly formatted broker name' do
      expect(rendered).to have_selector('span')
      expect(rendered).to have_text(formatted_name)
    end

    it 'should display brokers email' do
      expect(rendered).to match("mailto")
    end
  end

  context 'insured home broker widget as consumer without broker agency accounts' do
    let!(:consumer_role) { FactoryBot.create(:consumer_role) }
    let(:broker_agency_profile){ FactoryBot.create(:broker_agency_profile) }
    let(:broker_agency_account) { FactoryBot.create(:broker_agency_account, broker_agency_profile_id: broker_agency_profile.id) }
    let(:person) { consumer_role.person }
    let!(:family) do
      f = FactoryBot.build(:family)
      f.family_members = [
        FactoryBot.build(:family_member, family: f, person: person, is_primary_applicant: true)
      ]
      f.broker_agency_accounts = [broker_agency_account]
      f.save
      f
    end
    let(:family_member) { family.family_members.last }
    let(:writing_agent) { nil }

    before :each do
      assign(:person, person)
      assign :family_members, [family_member]
      allow(person).to receive(:primary_family).and_return(family)
      allow(family).to receive(:current_broker_agency).and_return(nil)
      render 'insured/families/consumer_brokers_widget'
    end

    it 'should display broker widget for consumer' do
      expect(rendered).to have_selector('h3')
      expect(rendered).to have_text('Select a Broker or Assister')
    end

    it 'should display get help signing up button' do
      expect(rendered).to have_selector('a')
      expect(rendered).to have_text('Get Help Signing Up')
    end

    it 'should display get help signing up button' do
      expect(rendered).to_not have_text('Find Assistance Another Way')
    end
  end
end
