# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exchanges::IssuersController do
  let(:site)            { build(:benefit_sponsors_site, :with_owner_exempt_organization, :dc) }
  let(:issuer_profiles) { create_list(:benefit_sponsors_organizations_issuer_profile, 2, organization: site.owner_organization) }
  let(:user)            { double("user", :has_hbx_staff_role? => true) }

  before(:each) do
    EnrollRegistry[:issuers_tab].feature.stub(:is_enabled).and_return(true)
    sign_in(user)
  end

  context "#index" do
    before(:each) { get :index, xhr: true }

    it "should render template" do
      expect(response).to render_template(:index)
    end

    it "should return data" do
      expect(assigns[:data]).to be_present
    end

    it "should be successful" do
      expect(response).to be_successful
    end
  end
end
