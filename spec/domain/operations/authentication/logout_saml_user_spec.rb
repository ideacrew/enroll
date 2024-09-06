# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Authentication::LogoutSamlUser do

  subject { described_class.new }

  let(:session) { double }

  before do
    allow(session).to receive(:[]).with(:__saml_name_id).and_return(saml_name_id)
    allow(session).to receive(:[]).with(:__saml_session_index).and_return(saml_session_index)
  end

  describe "given no name id" do
    let(:saml_name_id) { nil }
    let(:saml_session_index) { nil }

    it "fails" do
      expect(subject.call(session).success?).to be_falsey
    end
  end

  describe "given a name id and no configuration for the saml logout url" do
    let(:saml_name_id) { "SOME NAME" }
    let(:saml_session_index) { nil }

    before do
      allow(SamlInformation).to receive(:idp_slo_target_url).and_return(nil)
    end

    it "fails" do
      expect(subject.call(session).success?).to be_falsey
    end
  end

  describe "given a session index and no saml service path" do
    let(:saml_name_id) { "SOME NAME" }
    let(:saml_session_index) { nil }

    before :each do
      allow(SamlInformation).to receive(:idp_slo_target_url).and_return("https://")
    end

    it "fails" do
      expect(subject.call(session).success?).to be_falsey
    end
  end

  describe "given a session index and valid saml service path" do
    let(:saml_name_id) { "SOME NAME" }
    let(:saml_session_index) { "ABCDEFG_12345" }

    before :each do
      allow(SamlInformation).to receive(:idp_slo_target_url).and_return("https://my.logout.example/saml/logout_endpoint")
      stub_request(:get, %r{https://my.logout.example/saml/logout_endpoint}).with do |req|
        path_matches = req.uri.path == "/saml/logout_endpoint"
        query = Rack::Utils.parse_nested_query req.uri.query
        path_matches && !query["SAMLRequest"].nil?
      end.to_return(body: "OK")
    end

    it "constructs and submits the logout payload" do
      expect(subject.call(session).success?).to be_truthy
    end
  end
end