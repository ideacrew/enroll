# frozen_string_literal: true

require "rails_helper"

RSpec.describe EnrollRegistryPolicy, "given an unlinked user" do
  let(:user) do
    instance_double(
      User,
      :person => nil
    )
  end

  let(:subject) { described_class.new(user, nil) }

  it "is not authorized to show" do
    expect(subject.show?).to be_falsey
  end
end

RSpec.describe EnrollRegistryPolicy, "given a linked, non-admin user" do
  let(:person) do
    instance_double(
      Person,
      :hbx_staff_role => nil
    )
  end
  let(:user) do
    instance_double(
      User,
      :person => person
    )
  end

  let(:subject) { described_class.new(user, nil) }

  it "is not authorized to show" do
    expect(subject.show?).to be_falsey
  end
end

RSpec.describe EnrollRegistryPolicy, "given a linked, admin user, in AWS_ENV 'prod'" do
  let(:hbx_staff_role) do
    instance_double(
      HbxStaffRole
    )
  end
  let(:person) do
    instance_double(
      Person,
      :hbx_staff_role => hbx_staff_role
    )
  end
  let(:user) do
    instance_double(
      User,
      :person => person
    )
  end

  let(:subject) { described_class.new(user, nil) }

  before :each do
    allow(ENV).to receive(:[]).with("AWS_ENV").and_return("prod")
  end

  it "is not authorized to show" do
    expect(subject.show?).to be_falsey
  end
end

RSpec.describe EnrollRegistryPolicy, "given a linked, admin user, in AWS_ENV that is not 'prod'" do
  let(:hbx_staff_role) do
    instance_double(
      HbxStaffRole
    )
  end
  let(:person) do
    instance_double(
      Person,
      :hbx_staff_role => hbx_staff_role
    )
  end
  let(:user) do
    instance_double(
      User,
      :person => person
    )
  end

  let(:subject) { described_class.new(user, nil) }

  before :each do
    allow(ENV).to receive(:[]).with("AWS_ENV").and_return("non-prod")
  end

  it "is authorized to show" do
    expect(subject.show?).to be_truthy
  end
end