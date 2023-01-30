# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V2::SlcspCalculatorController, :type => :controller, :dbclean => :after_each do
  let(:user) { FactoryBot.create(:user) }

  let!(:valid_params) do
    '{
        "householdConfirmation": true,
        "householdCount": 1,
        "taxYear": "2022",
        "state": "ME",
        "members": [
          {
            "primaryMember": true,
            "relationship": "self",
            "name": "Mark",
            "dob": {
              "month": "1",
              "day": "1",
              "year": "1979"
            },
            "residences": [
              {
                "county": {
                  "zipcode": "04003",
                  "name": "Cumberland County",
                  "fips": "23005",
                  "state": "ME"
                },
                "months": {
                  "jan": true,
                  "feb": true,
                  "mar": true,
                  "apr": true,
                  "may": true,
                  "jun": true,
                  "jul": true,
                  "aug": true,
                  "sep": true,
                  "oct": true,
                  "nov": true,
                  "dec": true
                }
              }
            ],
            "coverage": {
              "jan": true,
              "feb": true,
              "mar": true,
              "apr": true,
              "may": true,
              "jun": true,
              "jul": true,
              "aug": true,
              "sep": true,
              "oct": true,
              "nov": true,
              "dec": true
            }
          }
        ]
      }'
  end


  describe "POST estimate, without parameters" do
    before :each do
      post :estimate, body: "{}"
    end

    it "respond bad request" do
      expect(response.status).to eq 400
    end
  end

  describe "POST current" do
    before :each do
      post :estimate, body: valid_params
    end

    it "is successful" do
      expect(response.status).to eq 200
    end
  end
end