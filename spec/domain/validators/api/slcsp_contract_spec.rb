# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::Api::SlcspContract,  dbclean: :after_each do
  let!(:json_example) do
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

  let!(:invalid_residence_json_example) do
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
                  "zipcode": "",
                  "name": "",
                  "fips": "",
                  "state": ""
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

  context "Given valid parameter scenarios" do
    context "with all valid parameters" do
      it 'should succeed' do
        result = subject.call(JSON.parse(json_example))
        expect(result.success?).to be_truthy
      end
    end
  end

  context "Given invalid parameter scenarios" do
    it 'should fail with invalid parameters' do
      result = subject.call({})
      expect(result.success?).to be_falsey
    end

    it 'should fail without county information' do
      result = subject.call(JSON.parse(invalid_residence_json_example))
      expect(result.success?).to be_falsey
    end

    it 'should fail without the requiered parameters' do
      result = subject.call(JSON.parse(json_example).delete("taxYear"))
      expect(result.success?).to be_falsey
    end
    it 'should fail without the requiered parameters' do
      result = subject.call(JSON.parse(json_example).delete("residences"))
      expect(result.success?).to be_falsey
    end

  end
end