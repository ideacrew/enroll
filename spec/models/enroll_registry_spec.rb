# frozen_string_literal: true

require "rails_helper"

describe EnrollRegistry do
  it "uses the correct policy class" do
    expect(EnrollRegistry.policy_class).to eq EnrollRegistryPolicy
  end
end