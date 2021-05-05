# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Entities::Employers::EmployerStaffRoles::CoverageRecord do

  context "Given valid required parameters" do

    let(:contract)                  { BenefitSponsors::Validators::Employers::CoverageRecordContract.new }

    let(:required_params) do
      {
        ssn: nil,
        gender: nil,
        dob: nil,
        hired_on: nil,
        is_applying_coverage: false,
        has_other_coverage: false,
        is_owner: false,
        address: {
          kind: nil,
          address_1: nil,
          address_2: nil,
          address_3: nil,
          city: nil,
          county: nil,
          state: nil,
          location_state_code: nil,
          full_text: nil,
          zip: nil,
          country_name: nil
        },
        email: {
          kind: nil,
          address: nil
        },
        coverage_record_dependents: []
      }
    end

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new coverage record instance" do
        expect(described_class.new(required_params)).to be_a BenefitSponsors::Entities::Employers::EmployerStaffRoles::CoverageRecord
      end
    end
  end
end