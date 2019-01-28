require "rails_helper"

RSpec.describe "broker_agencies/broker_roles/confirmation.html.erb" do

  let(:broker_candidate) {::Forms::BrokerCandidate.new}

  context 'Broker successfully registers his account' do
    before :each do
      assign(:broker_candidate, broker_candidate)
      allow(broker_candidate).to receive(:broker_role?).and_return true
      render template: "broker_agencies/broker_roles/confirmation.html.erb"
    end

    it "should have confirmation text" do
      expect(rendered).to have_content("We Received Your Broker Application")
    end

    it "should have see more links" do
      expect(rendered).to have_content("See More")
    end

    it "should have download button" do
      expect(rendered).to have_content("Download")
    end

    it "should have css" do
      expect(rendered).to have_css("#broker_confimation_panel")
    end

    it "should have input fields for email" do
      expect(rendered).to have_selector("input[placeholder='First Name *']")
      expect(rendered).to have_selector("input[placeholder='Last Name *']")
      expect(rendered).to have_selector("input[placeholder='Email *']")
    end
  end

  context 'Broker staff successfully registers his account' do
    before :each do
      assign(:broker_candidate, broker_candidate)
      allow(broker_candidate).to receive(:broker_role?).and_return false
      render template: "broker_agencies/broker_roles/confirmation.html.erb"
    end

    it "should have confirmation text" do
      expect(rendered).not_to have_content("We Received Your Broker Application")
    end

    it "should have see more links" do
      expect(rendered).not_to have_content("See More")
    end

    it "should have download button" do
      expect(rendered).not_to have_content("Download")
    end

    it "should have css" do
      expect(rendered).not_to have_css("#broker_confimation_panel")
    end

    it "should have input fields for email" do
      expect(rendered).not_to have_selector("input[placeholder='First Name *']")
      expect(rendered).not_to have_selector("input[placeholder='Last Name *']")
      expect(rendered).not_to have_selector("input[placeholder='Email *']")
    end
  end
end