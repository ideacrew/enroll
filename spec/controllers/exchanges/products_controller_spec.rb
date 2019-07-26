# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exchanges::ProductsController do
  let(:product) { create(:benefit_markets_products_health_products_health_product, :with_issuer_profile) }
  let(:user)      { double("user", :has_hbx_staff_role? => true) }

  before(:each) { sign_in(user) }

  context "#index" do
    before(:each) { get :index, xhr: true, params: { issuer_id: product.issuer_profile_id } }

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
