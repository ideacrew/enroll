require 'rails_helper'

RSpec.describe "_consumer_brokers_widget.html.erb" do

  context 'insured home broker widget as consumer' do
    let!(:consumer_role) { FactoryGirl.create(:consumer_role) }
    let(:person) { consumer_role.person }
    let!(:family) do
      f = FactoryGirl.build(:family)
      f.family_members = [
        FactoryGirl.build(:family_member, family: f, person: person, is_primary_applicant: true)
      ]
      f.broker_agency_accounts = [
        FactoryGirl.build(:broker_agency_account, family: f)
      ]
      f.save
      f
    end
    let(:family_member) { family.family_members.last }

    before :each do
      assign(:person, person)
      assign :family_members, [family_member]
      render 'insured/families/consumer_brokers_widget'
    end

    it "should display broker widget for consumer" do
      expect(rendered).to have_selector('h4', "Your Broker")
    end

    it "should display brokers email" do
      expect(rendered).to match("mailto")
    end

  end

end
