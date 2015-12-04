require 'rails_helper'

RSpec.describe "_consumer_brokers_widget.html.erb" do

  context 'insured home right column as consumer' do
    let(:user){ FactoryGirl.create(:user, person: person, roles: ["consumer"]) }
    let(:person) { FactoryGirl.create(:person, :with_consumer_role) }

    before :each do
      sign_in(user)
      assign(:person, person)
      render :partial => 'insured/families/consumer_brokers_widget'
    end

    it "should be a success" do
      expect(response).to have_http_status(:success)
    end

    it "should display broker widget for consumer" do
      expect(rendered).to have_selector('h4', "Your Broker")
    end

  end

end
