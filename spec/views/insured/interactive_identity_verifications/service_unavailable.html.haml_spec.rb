require "rails_helper"

describe "insured/interactive_identity_verifications/service_unavailable" do
  it "should show a message about the service being down and asking the user to try back later" do
    render :template => "insured/interactive_identity_verifications/service_unavailable.html.haml"
    expect(rendered).to include("We’re sorry. The third-party service used to confirm your identity is currently unavailable. Please try again later. If you continue to receive this message after trying several times, please call DC Health Link customer service for assistance at 1-855-532-5465.")
  end
end
