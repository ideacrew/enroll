# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SponsoredBenefits::BrokerAgencyPlanDesignOrganizationPolicy, "authorizing managing of quotes" do
  let(:broker_agency_profile_id) { BSON::ObjectId.new }
  let(:broker_agency_profile) { instance_double(BenefitSponsors::Organizations::BrokerAgencyProfile, id: broker_agency_profile_id) }
  let(:user) { instance_double(User) }
  let(:person) { instance_double(Person) }
  let(:authorized_staff_role) do
    instance_double(
      BrokerAgencyStaffRole,
      is_active?: true,
      benefit_sponsors_broker_agency_profile_id: broker_agency_profile_id
    )
  end
  let(:authorized_broker_role) do
    instance_double(
      BrokerRole,
      active?: true,
      benefit_sponsors_broker_agency_profile_id: broker_agency_profile_id
    )
  end
  let(:unauthorized_broker_role) do
    instance_double(
      BrokerRole,
      active?: true,
      benefit_sponsors_broker_agency_profile_id: "SOMETHING ELSE ENTIRELY"
    )
  end

  subject { described_class.new(user, broker_agency_profile) }

  it "denies a nobody" do
    allow(user).to receive(:has_hbx_staff_role?).and_return(false)
    allow(user).to receive(:person).and_return(nil)
    expect(subject.manage_quotes?).to be_falsey
  end

  it "denies a person with no roles" do
    allow(user).to receive(:has_hbx_staff_role?).and_return(false)
    allow(user).to receive(:person).and_return(person)
    allow(person).to receive(:broker_agency_staff_roles).and_return([])
    allow(person).to receive(:broker_role).and_return(nil)
    expect(subject.manage_quotes?).to be_falsey
  end

  it "allows an hbx_staff user" do
    allow(user).to receive(:has_hbx_staff_role?).and_return(true)
    expect(subject.manage_quotes?).to be_truthy
  end

  it "allows a user with matching broker agency staff roles" do
    allow(user).to receive(:has_hbx_staff_role?).and_return(false)
    allow(user).to receive(:person).and_return(person)
    allow(person).to receive(:broker_agency_staff_roles).and_return([authorized_staff_role])
    expect(subject.manage_quotes?).to be_truthy
  end

  it "denies a user with no matching broker roles" do
    allow(user).to receive(:has_hbx_staff_role?).and_return(false)
    allow(user).to receive(:person).and_return(person)
    allow(person).to receive(:broker_agency_staff_roles).and_return([])
    allow(person).to receive(:broker_role).and_return(unauthorized_broker_role)
    expect(subject.manage_quotes?).to be_falsey
  end

  it "allows a user with matching broker roles" do
    allow(user).to receive(:has_hbx_staff_role?).and_return(false)
    allow(user).to receive(:person).and_return(person)
    allow(person).to receive(:broker_agency_staff_roles).and_return([])
    allow(person).to receive(:broker_role).and_return(authorized_broker_role)
    expect(subject.manage_quotes?).to be_truthy
  end
end