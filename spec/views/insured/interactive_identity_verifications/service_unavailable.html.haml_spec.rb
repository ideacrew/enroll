require "rails_helper"

describe "insured/interactive_identity_verifications/service_unavailable" do
  it "should show a message about the service being down and asking the user to try back later" do
    render :template => "insured/interactive_identity_verifications/service_unavailable.html.haml"
    expect(rendered).to include("The Identity Proofing service is currently unavailable, please try again later.")
  end
end
