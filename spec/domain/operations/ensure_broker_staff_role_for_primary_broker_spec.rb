# frozen_string_literal: true

require "rails_helper"

describe Operations::EnsureBrokerStaffRoleForPrimaryBroker, "given an invalid scenario" do
  subject do
    described_class.new(:some_garbage)
  end

  it "raises an error" do
    expect { subject }.to raise_error(ArgumentError)
  end
end

describe Operations::EnsureBrokerStaffRoleForPrimaryBroker, "when:
  - it is for the scenario of :consumer_role_linked
  - the person has no broker role", dbclean: :after_each do

  let(:operation) do
    described_class.new(:consumer_role_linked)
  end

  let(:consumer_role) do
    FactoryBot.create(:consumer_role)
  end

  let(:person) do
    pers = consumer_role.person
    pers.user = user
    pers.save!
    pers
  end

  let(:user) do
    FactoryBot.create(:user)
  end

  before :each do
    operation.call(nil)
  end

  it "does not add a staff role" do
    expect(person.broker_agency_staff_roles).to eq []
  end
end

describe Operations::EnsureBrokerStaffRoleForPrimaryBroker, "when:
  - it is for the scenario of :consumer_role_linked
  - the person has an unapproved broker role", dbclean: :after_each do

  let(:operation) do
    described_class.new(:consumer_role_linked)
  end

  let(:consumer_role) do
    FactoryBot.create(:consumer_role)
  end

  let(:person) do
    pers = consumer_role.person
    pers.user = user
    pers.save!
    pers
  end

  let(:broker_agency_profile) do
    FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile)
  end

  let(:user) do
    FactoryBot.create(:user)
  end

  let(:existing_broker_staff_role) do
    person.broker_agency_staff_roles.first
  end

  let(:broker_role) do
    role = BrokerRole.new(
      :broker_agency_profile => broker_agency_profile,
      :aasm_state => "applicant",
      :npn => "123456789",
      :provider_kind => "broker"
    )
    person.broker_role = role
    person.save!
    person.broker_role
  end

  before :each do
    operation.call(broker_role)
  end

  it "does not add a staff role" do
    expect(person.broker_agency_staff_roles).to eq []
  end
end

describe Operations::EnsureBrokerStaffRoleForPrimaryBroker, "when:
  - it is for the scenario of :consumer_role_linked
  - the person has an approved broker role
  - the person already has a broker staff role for the same brokerage", dbclean: :after_each do
  let(:operation) do
    described_class.new(:consumer_role_linked)
  end

  let(:consumer_role) do
    FactoryBot.create(:consumer_role)
  end

  let(:person) do
    pers = consumer_role.person
    pers.user = user
    pers.broker_agency_staff_roles << BrokerAgencyStaffRole.new(
      aasm_state: "broker_agency_pending",
      broker_agency_profile: broker_agency_profile
    )
    pers.save!
    pers
  end

  let(:broker_agency_profile) do
    FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile)
  end

  let(:user) do
    FactoryBot.create(:user)
  end

  let(:existing_broker_staff_role) do
    person.broker_agency_staff_roles.first
  end

  let(:broker_role) do
    role = BrokerRole.new(
      :broker_agency_profile => broker_agency_profile,
      :aasm_state => "active",
      :npn => "123456789",
      :provider_kind => "broker"
    )
    person.broker_role = role
    person.save!
    person.broker_role
  end

  before :each do
    operation.call(broker_role)
  end

  it "doesn't add another broker staff role" do
    expect(person.broker_agency_staff_roles.count).to eq 1
  end

  it "activates the broker staff role" do
    expect(existing_broker_staff_role.aasm_state).to eq "active"
  end
end

describe Operations::EnsureBrokerStaffRoleForPrimaryBroker, "when:
  - it is for the scenario of :consumer_role_linked
  - the person has an approved broker role
  - the person doesn't have a broker staff role for the same brokerage", dbclean: :after_each do
  let(:operation) do
    described_class.new(:consumer_role_linked)
  end

  let(:consumer_role) do
    FactoryBot.create(:consumer_role)
  end

  let(:person) do
    pers = consumer_role.person
    pers.user = user
    pers.save!
    pers
  end

  let(:broker_agency_profile) do
    FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile)
  end

  let(:user) do
    FactoryBot.create(:user)
  end

  let(:broker_role) do
    role = BrokerRole.new(
      :broker_agency_profile => broker_agency_profile,
      :aasm_state => "active",
      :npn => "123456789",
      :provider_kind => "broker"
    )
    person.broker_role = role
    person.save!
    person.broker_role
  end

  before :each do
    operation.call(broker_role)
  end

  it "creates a new broker staff role for the same brokerage" do
    expect(person.broker_agency_staff_roles.first.broker_agency_profile.id).to eq broker_agency_profile.id
  end

  it "sets the new role to active" do
    new_broker_staff_role = person.broker_agency_staff_roles.first
    expect(new_broker_staff_role.aasm_state).to eq "active"
  end
end