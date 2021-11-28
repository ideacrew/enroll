# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExceptionsController, :type => :controller, :dbclean => :after_each do
  let(:user) { FactoryBot.create(:user) }
  before do
    sign_in(user)
  end
  context "GET #show" do
    context "custom_exceptions_controller feature" do
      context "enabled" do
        before do
          EnrollRegistry[:custom_exceptions_controller].feature.stub(:is_enabled).and_return(true)
          get :show, params: {id: 1}
        end

        it "should redirect to custom exception view" do
          expect(response).to render_template("exceptions/show")
        end
      end

      context "disabled" do
        before do
          EnrollRegistry[:custom_exceptions_controller].feature.stub(:is_enabled).and_return(false)
          get :show, params: {id: 1}
        end

        it "should redirect to custom exception view" do
          expect(response).to render_template(:file => "#{Rails.root}/public/500.html")
        end
      end
    end
  end
end