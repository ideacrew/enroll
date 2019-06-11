require "rails_helper"

RSpec.describe BenefitSponsors::Validators::BrokerAgencyProfileCreateRequest::PARAMS do
  subject { BenefitSponsors::Validators::BrokerAgencyProfileCreateRequest::PARAMS.call(data) }
  
  let(:base_valid_data) do
    {
      "legal_name" => "Some Brokerage Company",
      "first_name" => "Some",
      "last_name" => "Broker",
      "dob" => "10/13/1997",
      "npn" => "123456789",
      "languages" => ["en"],
      "practice_area" => "shop",
      "evening_weekend_hours" => "no",
      "accepts_new_clients" => "false",
      "email" => "asdf@dude.com",
      "ach_information" => {
        "ach_account" => "1234",
        "ach_confirmation" => "1234"
      },
      "phone" => {
        "phone_area_code" => "000",
        "phone_number" => "1234567",
        "phone_extension" => "X2345"
      },
      "address" => {
        "address_1" => "123 Some Street",
        "city" => "Some City",
        "state" => "MD",
        "zip" => "20002"
      }
    }
  end

  context "with valid data, but no office locations" do
    let(:data) do
      base_valid_data
    end

    it "is valid" do
      expect(subject.success?).to be_truthy
    end
  end

  context "with valid data, and a valid office location" do
    let(:data) do
      base_valid_data.merge({
        "office_locations" => [
          {
            "kind" => "branch",
            "address" => {
              "address_1" => "123 Some Street",
              "address_2" => "And a PO Box",
              "city" => "Some City",
              "state" => "MD",
              "zip" => "20002"
            },
            "phone" => {
              "phone_area_code" => "000",
              "phone_number" => "1234567"
            }
          }
        ]
      })
    end

    it "is valid" do
      expect(subject.success?).to be_truthy
    end
  end
end