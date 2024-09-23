# frozen_string_literal: true

require "rails_helper"

RSpec.describe RemoteIdentityProofingStatus, "given:
  - a consumer role
  - with an associated user
  - that hasn't passed ridp at either level" do

  let(:consumer_role) do
    instance_double(
      ConsumerRole,
      person: person,
      identity_verified?: false
    )
  end

  let(:person) do
    instance_double(
      Person,
      user: user
    )
  end

  let(:user) do
    instance_double(
      User,
      identity_verified?: false
    )
  end

  it "isn't complete" do
    expect(described_class.is_complete_for_consumer_role?(consumer_role)).to be_falsey
  end
end

RSpec.describe RemoteIdentityProofingStatus, "given:
  - a consumer role
  - that has passed RIDP at the consumer role level" do

  let(:consumer_role) do
    instance_double(
      ConsumerRole,
      person: person,
      identity_verified?: true
    )
  end

  let(:person) do
    instance_double(
      Person,
      user: user
    )
  end

  let(:user) do
    instance_double(
      User,
      identity_verified?: false
    )
  end

  it "is complete" do
    expect(described_class.is_complete_for_consumer_role?(consumer_role)).to be_truthy
  end
end

RSpec.describe RemoteIdentityProofingStatus, "given:
  - a consumer role
  - with an associated user
  - that has NOT passed RIDP at the consumer role level
  - that HAS passed RIDP at the user level" do

  let(:consumer_role) do
    instance_double(
      ConsumerRole,
      person: person,
      identity_verified?: false
    )
  end

  let(:person) do
    instance_double(
      Person,
      user: user
    )
  end

  let(:user) do
    instance_double(
      User,
      identity_verified?: true
    )
  end

  it "is complete" do
    expect(described_class.is_complete_for_consumer_role?(consumer_role)).to be_truthy
  end
end

RSpec.describe RemoteIdentityProofingStatus, "given:
  - a person
  - with an associated user
  - that hasn't passed ridp at either level" do

  let(:consumer_role) do
    instance_double(
      ConsumerRole,
      identity_verified?: false
    )
  end

  let(:person) do
    instance_double(
      Person,
      consumer_role: consumer_role,
      user: user
    )
  end

  let(:user) do
    instance_double(
      User,
      identity_verified?: false
    )
  end

  it "isn't complete" do
    expect(described_class.is_complete_for_person?(person)).to be_falsey
  end
end

RSpec.describe RemoteIdentityProofingStatus, "given:
  - a person
  - that has passed RIDP at the consumer role level" do

  let(:consumer_role) do
    instance_double(
      ConsumerRole,
      identity_verified?: true
    )
  end

  let(:person) do
    instance_double(
      Person,
      consumer_role: consumer_role,
      user: user
    )
  end

  let(:user) do
    instance_double(
      User,
      identity_verified?: false
    )
  end

  it "is complete" do
    expect(described_class.is_complete_for_person?(person)).to be_truthy
  end
end

RSpec.describe RemoteIdentityProofingStatus, "given:
  - a person
  - with an associated user
  - that has NOT passed RIDP at the consumer role level
  - that HAS passed RIDP at the user level" do

  let(:consumer_role) do
    instance_double(
      ConsumerRole,
      identity_verified?: false
    )
  end

  let(:person) do
    instance_double(
      Person,
      consumer_role: consumer_role,
      user: user
    )
  end

  let(:user) do
    instance_double(
      User,
      identity_verified?: true
    )
  end

  it "is complete" do
    expect(described_class.is_complete_for_person?(person)).to be_truthy
  end
end