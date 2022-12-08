# frozen_string_literal: true

require 'rails_helper'

describe "financial_assistance/applications/index.html.erb" do
  let(:person) { FactoryBot.create(:person) }
  let(:user) { FactoryBot.create(:user, person: person) }
  let!(:hbx_profile) {FactoryBot.create(:hbx_profile)}
  let!(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
  let(:current_year) { oe_year - 1 }
  let(:oe_year) { Family.application_applicable_year }

  before :each do
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:iap_year_selection).and_return(true)
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:oe_application_warning_display).and_return(oe_application_warning_display)
    sign_in user
    assign :person, person
  end

  context 'when feature is enabled' do
    let(:oe_application_warning_display) { true }

    it "should have text" do
      render template: "financial_assistance/applications/index.html.erb"
      expect(rendered).to have_content(l10n('faa.coverage_update_reminder', year: current_year, year2: oe_year))
    end
  end

  context 'when feature is disabled' do
    let(:oe_application_warning_display) { false }

    it "should not display text" do
      render template: "financial_assistance/applications/index.html.erb"
      expect(rendered).not_to have_content(l10n('faa.coverage_update_reminder', year: current_year, year2: oe_year))
    end
  end
end
