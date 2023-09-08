# frozen_string_literal: true
require "pry"
require "rails_helper"
include FinancialAssistance::Engine.routes.url_helpers
include FinancialAssistance::ApplicationHelper
include FinancialAssistance::L10nHelper
include ActionView::Helpers::TranslationHelper
include GlossaryHelper
include ConsumerRolesHelper

RSpec.describe "components/financial_assistance/app/views/financial_assistance/applicants/_dependent_form.html.erb" do

  let(:application)       { FactoryBot.create(:financial_assistance_application, :with_applicants) }
  let(:primary_applicant) { application.applicants.first }
  before :each do
    stub_template('shared/_consumer_fields' => '')
    stub_template('shared/_error_warning'   => '')
    stub_template('devise/passwords/_edit' => '')
    stub_template('users/security_question_responses/_edit_modal' => '')
    stub_template('shared/_modal_support_text_household' => '')
    stub_template('shared/_ssn_coverage_msg' => '')
    allow(view).to receive(:policy_helper).and_return(double("PersonPolicy", updateable?: true))
    assign(:application, application)
    assign(:applicant, application.applicants.second)
    render partial: "financial_assistance/applicants/dependent_form"
  end

  it "has an ssn_field" do
    expect(rendered).to have_selector("input[placeholder='SOCIAL SECURITY']")
  end
end
