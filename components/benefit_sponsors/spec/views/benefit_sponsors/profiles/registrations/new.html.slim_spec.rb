# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

class ApplicationHelperModStubber
  extend ::BenefitSponsors::Employers::EmployerHelper
end

RSpec.describe "benefit_sponsors/profiles/registrations/new", :type => :view, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  let(:br_agency) { BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_new(profile_type: 'broker_agency', portal: true) }
  let(:ga_agency) { BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_new(profile_type: 'general_agency', portal: true) }
  let(:bs_agency) { BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_new(profile_type: 'benefit_sponsor', portal: true) }

  before :each do
    current_benefit_market_catalog
    view.extend Pundit
    view.extend BenefitSponsors::Engine.routes.url_helpers
    allow(view).to receive(:render).with(:partial => "shared/error_messages").and_return("")
    allow(view).to receive(:render).with("shared/error_messages",anything).and_return("")

    allow(view).to receive(:render).with({:template=>"benefit_sponsors/profiles/registrations/new"}, {}).and_call_original
    allow(view).to receive(:render).with("benefit_sponsors/shared/error_messages", anything).and_call_original
    allow(view).to receive(:render).with("./ui-components/v1/forms/employer_registration/employer_profile_form", anything).and_call_original
    allow(view).to receive(:render).with("benefit_sponsors/profiles/registrations/sic_help", anything).and_call_original
    allow(view).to receive(:render).with({:locals=> anything, :partial=> "./ui-components/v1/forms/employer_registration/staff_role_information"}).and_call_original
    allow(view).to receive(:render).with({:locals=> anything, :partial=> "./ui-components/v1/forms/office_locations/office_location_fields"}).and_call_original
    allow(view).to receive(:render).with({:locals=> anything, :partial=> "./ui-components/v1/forms/office_locations/address"}).and_call_original
    allow(view).to receive(:render).with({:locals=> anything, :partial=> "./ui-components/v1/forms/office_locations/phone"}).and_call_original
    allow(view).to receive(:render).with({:locals=> anything, :partial=> "./ui-components/v1/forms/general_agency_registration/personal_information"}).and_call_original
    allow(view).to receive(:render).with({:locals=> anything, :partial=> "./ui-components/v1/forms/general_agency_registration/general_agency_information"}).and_call_original
    allow(view).to receive(:render).with({:locals=> anything, :partial=> "./ui-components/v1/forms/general_agency_registration/general_agency_profile_information"}).and_call_original
    allow(view).to receive(:render).with({:locals=> anything, :partial=> "./ui-components/v1/forms/broker_registration/personal_information"}).and_call_original
    allow(view).to receive(:render).with({:locals=> anything, :partial=> "./ui-components/v1/forms/broker_registration/broker_agency_information"}).and_call_original
    allow(view).to receive(:render).with({:locals=> anything, :partial=> "./ui-components/v1/forms/broker_registration/broker_profile_information"}).and_call_original
    allow(view).to receive(:render).with({:partial=> "benefit_sponsors/profiles/registrations/general_agency_registration_form"}).and_call_original
    allow(view).to receive(:render).with({:partial=> "benefit_sponsors/profiles/registrations/broker_registration_form"}).and_call_original

    allow(EnrollRegistry).to receive(:feature_enabled?).with(:allow_alphanumeric_npn).and_call_original
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:broker_attestation_fields).and_call_original
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:fehb_market).and_call_original
  end

  it "should display recaptcha for broker agency" do
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:registration_broker_recaptcha).and_return(true)
    @profile_type = 'broker_agency'
    assign(:agency, br_agency)
    render template: "benefit_sponsors/profiles/registrations/new"
    expect(rendered).to have_selector(:css,'.g-recaptcha')
  end

  it "should not display recaptcha for broker agency" do
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:registration_broker_recaptcha).and_return(false)
    @profile_type = 'broker_agency'
    assign(:agency, br_agency)
    render template: "benefit_sponsors/profiles/registrations/new"
    expect(rendered).not_to have_selector(:css,'.g-recaptcha')
  end

  it "should display recaptcha for general agency" do
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:registration_ga_recaptcha).and_return(true)
    @profile_type = 'general_agency'
    assign(:agency, ga_agency)
    render template: "benefit_sponsors/profiles/registrations/new"
    expect(rendered).to have_selector(:css,'.g-recaptcha')
  end

  it "should not display recaptcha for general agency" do
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:registration_ga_recaptcha).and_return(false)
    @profile_type = 'general_agency'
    assign(:agency, ga_agency)
    render template: "benefit_sponsors/profiles/registrations/new"
    expect(rendered).not_to have_selector(:css,'.g-recaptcha')
  end

  it "should display recaptcha for benefit sponsor" do
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:registration_sponsor_recaptcha).and_return(true)
    @profile_type = 'benefit_sponsor'
    assign(:agency, bs_agency)
    render template: "benefit_sponsors/profiles/registrations/new"
    expect(rendered).to have_selector(:css,'.g-recaptcha')
  end

  it "should not display recaptcha for benefit sponsor" do
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:registration_sponsor_recaptcha).and_return(false)
    @profile_type = 'benefit_sponsor'
    assign(:agency, bs_agency)
    render template: "benefit_sponsors/profiles/registrations/new"
    expect(rendered).not_to have_selector(:css,'.g-recaptcha')
  end

end

RSpec.describe "benefit_sponsors/profiles/registrations/new", :type => :view, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"

  let(:user) { FactoryBot.create(:user) }
  let(:agency) { BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_new(profile_type: 'benefit_sponsor', portal: true) }

  before :each do
    current_benefit_market_catalog
    view.extend Pundit
    view.extend BenefitSponsors::Engine.routes.url_helpers
    @profile_type = 'benefit_sponsor'
    assign(:agency, agency)
    sign_in user
    render template: "benefit_sponsors/profiles/registrations/new"
  end

  it "should display county based on exchange" do
    if Settings.aca.address_query_county
      expect(rendered).to have_selector('label', text: 'County')
    else
      expect(rendered).to_not have_selector('label', text: 'County')
    end
  end

  it "should display referred by based on exchange" do
    if ApplicationHelperModStubber.display_referred_by_field_for_employer?
      expect(rendered).to have_content('Referred By *')
    else
      expect(rendered).to_not have_content('Referred By *')
    end
  end

  it "should display SIC code and tool tip based on exchange" do
    if ApplicationHelperModStubber.display_sic_field_for_employer?
      expect(rendered).to have_selector('#sicHelperToggle')
      expect(rendered).to have_selector('label', text: 'SIC Code *')
    else
      expect(rendered).to_not have_selector('#sicHelperToggle')
      expect(rendered).to_not have_selector('label', text: 'SIC Code *')
    end
  end
end
