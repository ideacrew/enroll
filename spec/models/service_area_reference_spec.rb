require 'rails_helper'

RSpec.describe ServiceAreaReference, type: :model do
  subject { ServiceAreaReference.new }

  it "has a valid factory" do
    expect(create(:service_area_reference)).to be_valid
  end
end
