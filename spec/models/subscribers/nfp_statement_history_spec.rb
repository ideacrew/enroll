require "rails_helper"

describe Subscribers::NfpStatementHistory do
  it "should subscribe to the correct event" do
    expect(Subscribers::NfpStatementHistory.subscription_details).to eq ["acapi.info.events.employer.nfp_statement_summary_success"]
  end
end
