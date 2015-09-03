require "rails_helper"

RSpec.describe "broker_agencies/broker_roles/_existing_broker_agency_form.html.erb" do
  before :each do
    assign :broker_candidate, Forms::BrokerCandidate.new
    render template: "broker_agencies/broker_roles/_existing_broker_agency_form.html.erb"
  end

  it "should have search area" do
    expect(rendered).to have_selector("input[placeholder='Name/FEIN']")
  end
end
