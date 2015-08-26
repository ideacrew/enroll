require 'rails_helper'
require File.join(Rails.root, "spec", "support", "acapi_vocabulary_spec_helpers")

RSpec.describe "events/identity_verification/interactive_verification_override.xml.haml" do

  describe "given a generated transaction id" do
    include AcapiVocabularySpecHelpers

    before(:all) do
      download_vocabularies
    end

    let(:transaction_id) { "some transaction id" }

    before :each do
      render :template => "events/identity_verification/interactive_verification_override.xml", :locals => { :transaction_id => transaction_id }
    end

    it "should be schema valid" do
      expect(validate_with_schema(Nokogiri::XML(rendered))).to eq []
    end


  end
end
