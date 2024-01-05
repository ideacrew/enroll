# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'default broker consumer enhancements settings' do
  it "has :broker_role_consumer_enhancement disabled" do
    expect(
      EnrollRegistry.feature_enabled?(:broker_role_consumer_enhancement)
    ).to be_falsey
  end
end