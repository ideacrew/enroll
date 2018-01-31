require 'rails_helper'
require File.join(Rails.root, "spec", "support", "acapi_vocabulary_spec_helpers")

RSpec.describe "events/identity_verification/interactive_questions_response.xml.haml" do
  include AcapiVocabularySpecHelpers

  before(:all) do
    download_vocabularies
  end

  let(:mock_response) { IdentityVerification::InteractiveVerification::Response.new(:response_id => "2343", :response_text => "Response A") }
  let(:mock_question) { IdentityVerification::InteractiveVerification::Question.new(:question_id => "1", :question_text => "first_question_text", :responses => [mock_response], :response_id => "2343") }
  let(:mock_verification) { IdentityVerification::InteractiveVerification.new(:questions => [mock_question]) }

  before :each do
    render :template => "events/identity_verification/interactive_questions_response.xml", :locals => { :session => mock_verification }
  end

  it "should be schema valid" do
    expect(validate_with_schema(Nokogiri::XML(rendered))).to eq []
  end

end
