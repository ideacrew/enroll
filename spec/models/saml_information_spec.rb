require "rails_helper"

shared_examples "a configuration lookup" do |key|
  it "with a key of #{key}" do
    expect(SamlInformation.send(key.to_sym)).not_to be_blank
  end
end

describe SamlInformation do
  it_behaves_like "a configuration lookup", "assertion_consumer_service_url"
  it_behaves_like "a configuration lookup", "assertion_consumer_logout_service_url"
  it_behaves_like "a configuration lookup", "issuer"
  it_behaves_like "a configuration lookup", 'idp_entity_id'
  it_behaves_like "a configuration lookup", 'idp_sso_target_url'
  it_behaves_like "a configuration lookup", 'idp_slo_target_url'
  it_behaves_like "a configuration lookup", 'idp_cert'
  it_behaves_like "a configuration lookup", 'name_identifier_format'
  it_behaves_like "a configuration lookup", 'idp_cert_fingerprint'
  it_behaves_like "a configuration lookup", 'idp_cert_fingerprint_algorithm'
end
