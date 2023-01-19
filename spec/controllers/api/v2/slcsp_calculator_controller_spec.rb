# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V2::SlcspCalculatorController, :type => :controller, :dbclean => :after_each do
  let(:user) { FactoryBot.create(:user) }

  describe "GET estimate, without parameters" do
    before :each do
      post :estimate
    end

    it "respond bad request" do
      expect(response.status).to eq 400
    end
  end

  describe "GET current" do
    let(:valid_params) do
      {
        taxYear: 2022
      }
    end

    before :each do
      post :estimate, params: valid_params
    end

    it "is successful" do
      expect(response.status).to eq 200
    end

    it "renders the user" do
      parsed = JSON.parse(response.body)
      expect(parsed["values"].count).to eq 12
    end
  end
end