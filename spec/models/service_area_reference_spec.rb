require 'rails_helper'

RSpec.describe ServiceAreaReference, type: :model do
  subject { ServiceAreaReference.new }

  it "has a valid factory" do
    expect(create(:service_area_reference)).to be_valid
  end

  it { is_expected.to validate_presence_of :service_area_id }
  it { is_expected.to validate_presence_of :service_area_name }
  it { is_expected.to validate_presence_of :serves_entire_state }

  context "serves_entire_state is false" do
    subject { build(:service_area_reference, serves_entire_state: false) }

    it { is_expected.to validate_presence_of :county_name }
    it { is_expected.to validate_presence_of :serves_partial_county }

    context "serves_partial_county is true" do
      subject { build(:service_area_reference, serves_entire_state: false, serves_partial_county: true) }

      it { is_expected.to validate_presence_of :partial_county_justification }
      it { is_expected.to validate_presence_of :service_area_zipcode }
    end
  end
end
