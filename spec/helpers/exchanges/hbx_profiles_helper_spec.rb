require "rails_helper"

RSpec.describe Exchanges::HbxProfilesHelper, :type => :helper do

  context "update_fein_errors" do
    let(:organization){ FactoryGirl.create(:organization) }
    let(:organization2){ FactoryGirl.create(:organization) }
    let(:new_invalid_fein) { "234-839" }
    let(:org_fein) { "234-839" }
    let(:org_params) {
      {
        "organization" => { "new_fein" => new_invalid_fein }
      }
    }
    let(:error_message1) {
      {:fein=> ["#{new_invalid_fein} is not a valid"]}
    }
    let(:error_message2) {
      {:fein=> ["is already taken"]}
    }

    it "should show error message: FEIN must be at least 9 digits" do
      expect(helper.update_fein_errors(error_message1, new_invalid_fein)).to eq ["FEIN must be at least 9 digits"]
    end

    it "should show error message: FEIN matches HBX ID & Legal Name" do
      expect(helper.update_fein_errors(error_message2, organization2.fein)).to eq ["FEIN matches HBX ID #{organization2.hbx_id}, #{organization2.legal_name}"]
    end
  end
end
