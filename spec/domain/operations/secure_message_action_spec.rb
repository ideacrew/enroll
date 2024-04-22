# frozen_string_literal: true

require "rails_helper"

module Operations
  RSpec.describe SecureMessageAction do
    let(:user) { FactoryBot.create(:user) }

    subject do
      described_class.new.call(params: params, user: user)
    end

    describe "not passing :resource_id, :subject, :actions_id, :body :resource_name" do

      let(:params) { { }}
      let(:error_message) do
        {
          :resource_id => ['is missing', 'must be a string'],
          :resource_name => ['is missing', 'must be a string'],
          :actions_id => ['is missing', 'must be a string'],
          :subject => ['is missing', 'must be a string'],
          :body => ['is missing', 'must be a string']
        }
      end

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.failure).to eq error_message
      end
    end

    describe "passing all params but with incorrect data" do

      let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, EnrollRegistry[:enroll_app].setting(:site_key).item) }
      let(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, site: site)}
      let(:employer_profile) {organization.employer_profile}

      let(:params) { { subject: 'Hello world', body: 'Hello world', actions_id: '1234', resource_id: organization.id.to_s, resource_name: organization.class.to_s }}
      let(:error_message) {{:message => [l10n('insured.resource_not_found')]}}

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.failure).to eq error_message
      end
    end

    describe "passing all params but with valid data" do

      let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, EnrollRegistry[:enroll_app].setting(:site_key).item) }
      let(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :"with_aca_shop_#{EnrollRegistry[:enroll_app].setting(:site_key).item}_employer_profile".to_sym, site: site)}
      let(:employer_profile) { organization.employer_profile }
      let(:person)           { FactoryBot.create(:person, :with_family) }

      let(:params) do
        if EnrollRegistry.feature_enabled?(:aca_shop_market)
          { subject: 'Hello world', body: 'Hello world', actions_id: '1234', resource_id: employer_profile.id.to_s, resource_name: employer_profile.class.to_s }
        else
          { subject: 'Hello world', body: 'Hello world', actions_id: '1234', resource_id: person.id.to_s, resource_name: person.class.to_s }
        end
      end

      it "should pass" do
        expect(subject).to be_success
        expect(subject.success).to eq true
      end
    end
  end
end
