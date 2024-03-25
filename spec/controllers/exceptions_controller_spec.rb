# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExceptionsController, :type => :controller, :dbclean => :after_each do
  # No login required
  context "GET #show" do
    context "custom_exceptions_controller feature" do
      context "enabled" do
        before do
          allow(EnrollRegistry[:custom_exceptions_controller].feature).to receive(:is_enabled).and_return(true)
          get :show, params: {id: 1}
        end

        it "should redirect to custom exception view" do
          expect(response).to render_template("exceptions/show")
        end
      end

      context "disabled" do
        before do
          allow(EnrollRegistry[:custom_exceptions_controller].feature).to receive(:is_enabled).and_return(false)
          get :show, params: {id: 1}
        end

        it "should redirect to custom exception view" do
          expect(subject.status).to eq(500)
          expect(response.body).to include("We're sorry, but something went wrong (500)")
        end
      end
    end
  end
end
