require 'rails_helper'

RSpec.describe CarrierServiceArea, type: :model, dbclean: :after_each do
  subject { CarrierServiceArea.new }

  it "has a valid factory" do
    expect(build(:carrier_service_area)).to be_valid
  end

  it { is_expected.to validate_presence_of :issuer_hios_id }
  it { is_expected.to validate_presence_of :service_area_id }
  it { is_expected.to validate_presence_of :service_area_name }
  it { is_expected.to validate_presence_of :serves_entire_state }

  context "serves_entire_state is false" do
    subject { build(:carrier_service_area, serves_entire_state: false) }

    it { is_expected.to validate_presence_of :county_name }
    it { is_expected.to validate_presence_of :county_code }
    it { is_expected.to validate_presence_of :state_code }
  end

  describe "class methods" do
    subject { CarrierServiceArea }
    let!(:full_state_service_area) { create(:carrier_service_area) }
    let!(:matching_service_area) { create(:carrier_service_area, :for_partial_state, service_area_zipcode: '01225') }
    let!(:non_matching_service_area) { create(:carrier_service_area, :for_partial_state, service_area_zipcode: "01001") }

    context "scopes" do
      describe "::serving_entire_state" do
        it "returns only the full state service areas" do
          expect(subject.serving_entire_state).to match([full_state_service_area])
        end
      end
    end

    context "::areas_valid_for_zip_code" do
      ## Note this requires a previously validated Mass. Zip Code
      it "returns the matching service areas" do
        expect(subject.areas_valid_for_zip_code(zip_code: '01225')).to match_array([full_state_service_area, matching_service_area])
      end
    end
  end ## End class method tests
end
