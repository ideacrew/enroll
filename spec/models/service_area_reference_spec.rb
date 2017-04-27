require 'rails_helper'

RSpec.describe ServiceAreaReference, type: :model do
  subject { ServiceAreaReference.new }

  it "has a valid factory" do
    expect(create(:service_area_reference)).to be_valid
  end

  it { is_expected.to validate_presence_of :hios_id }
  it { is_expected.to validate_presence_of :service_area_id }
  it { is_expected.to validate_presence_of :service_area_name }
  it { is_expected.to validate_presence_of :serves_entire_state }

  context "serves_entire_state is false" do
    subject { build(:service_area_reference, serves_entire_state: false) }

    it { is_expected.to validate_presence_of :county_name }
    it { is_expected.to validate_presence_of :county_code }
    it { is_expected.to validate_presence_of :state_code }
    it { is_expected.to validate_presence_of :serves_partial_county }
  end

  context "serves_partial_county is true" do
    subject { build(:service_area_reference, serves_entire_state: false, serves_partial_county: true) }

    it { is_expected.to validate_presence_of :partial_county_justification }
    it { is_expected.to validate_presence_of :service_area_zipcode }
  end

  describe "class methods" do
    subject { ServiceAreaReference }
    before :all do
      ServiceAreaReference.destroy_all
    end
    describe "scopes" do
      let!(:full_state_service_area) { create(:service_area_reference, service_area_name: "Full State Service") }
      let!(:partial_state_service_area) { create(:service_area_reference, :for_partial_state) }

      describe "::serving_entire_state" do
        it "returns only the full state service areas" do
          expect(subject.serving_entire_state).to match([full_state_service_area])
        end
      end
    end

    describe "::areas_valid_for_zip_code" do
      before :all do
        ServiceAreaReference.destroy_all
      end

      context "areas with full state service return true for all zip codes" do
        ## Note this requires a previously validated Mass. Zip Code
        let!(:full_state_service_area) { create(:service_area_reference) }
        let!(:matching_service_area) { create(:service_area_reference, :for_partial_state, service_area_zipcode: '01225') }
        let!(:matching_partial_county_area) { create(:service_area_reference, :for_partial_county, service_area_zipcode: '01225') }
        let!(:non_matching_service_area) { create(:service_area_reference, :for_partial_state, service_area_zipcode: "01001") }

        it "returns the matching service areas" do
          expect(subject.areas_valid_for_zip_code(zip_code: '01225')).to match_array([full_state_service_area, matching_service_area, matching_partial_county_area])
        end
      end
    end
  end ## End class method tests
end
