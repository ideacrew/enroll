# frozen_string_literal: true

require "rails_helper"

RSpec.describe "components/financial_assistance/app/views/financial_assistance/applicants/_edit.html.erb" do

  let(:application)       { FactoryBot.create(:financial_assistance_application, :with_applicants) }
  let(:primary_applicant) { application.applicants.first }
  before :each do
    stub_template('shared/_consumer_fields' => '')
    stub_template('shared/_error_warning'   => '')
    stub_template('devise/passwords/_edit' => '')
    stub_template('users/security_question_responses/_edit_modal' => '')
    stub_template('shared/_modal_support_text_household' => '')
    allow(view).to receive(:policy_helper).and_return(double("PersonPolicy", updateable?: true))
    assign(:application, application)
  end

  context "when applicant is the primary applicant" do
    before(:each) do
      assign(:applicant, primary_applicant)
      render partial: "financial_assistance/applicants/edit"
    end

    it "has ssn_field with readonly attribute" do
      expect(rendered).to have_selector("input[readonly='readonly'][placeholder='SOCIAL SECURITY']")
    end

    it "does not have have a delete_applicant_button" do
      expect(rendered).not_to have_selector("button#delete_applicant_button")
    end
  end

  context "when applicant is not the primary applicant" do
    before(:each) do
      assign(:applicant, application.applicants.second)
      render partial: "financial_assistance/applicants/edit"
    end
    it "has an ssn_field" do
      expect(rendered).to have_selector("input[placeholder='SOCIAL SECURITY']")
    end
  end
end
