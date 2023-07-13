# frozen_string_literal: true

require "rails_helper"

RSpec.describe SponsoredBenefits::PlanDesignOrganizationPolicy, "authorizing #view_proposals?" do
  let(:broker_agency_profile_id) { "A BROKER AGENCY PROFILE ID" }
  let(:general_agency_profile_id) { "A GENERAL AGENCY PROFILE ID" }
  let(:current_user) { instance_double(User, has_hbx_staff_role?: @is_hbx_staff, person: @person) }
  let(:plan_design_organization) { instance_double(SponsoredBenefits::Organizations::PlanDesignOrganization, owner_profile_id: @owner_profile_id) }
  let(:subject) { described_class.new(current_user, plan_design_organization) }
  let(:person_with_no_roles) do
    instance_double(
      Person,
      active_broker_staff_roles: [],
      broker_role: nil,
      active_general_agency_staff_roles: []
    )
  end
  let(:person_with_matching_broker_role) do
    instance_double(
      Person,
      active_broker_staff_roles: [],
      broker_role: matching_broker_role,
      active_general_agency_staff_roles: []
    )
  end
  let(:person_with_matching_broker_staff_role) do
    instance_double(
      Person,
      active_broker_staff_roles: [matching_broker_staff_role],
      broker_role: nil,
      active_general_agency_staff_roles: []
    )
  end
  let(:person_with_matching_ga_staff_role) do
    instance_double(
      Person,
      active_broker_staff_roles: [],
      broker_role: nil,
      active_general_agency_staff_roles: [matching_ga_staff_role]
    )
  end
  let(:matching_broker_role) do
    instance_double(
      BrokerRole,
      active?: true,
      benefit_sponsors_broker_agency_profile_id: broker_agency_profile_id
    )
  end
  let(:matching_broker_staff_role) do
    instance_double(
      BrokerAgencyStaffRole,
      active?: true,
      benefit_sponsors_broker_agency_profile_id: broker_agency_profile_id
    )
  end
  let(:matching_ga_staff_role) do
    instance_double(
      GeneralAgencyStaffRole,
      benefit_sponsors_general_agency_profile_id: general_agency_profile_id
    )
  end
  let(:general_agency_accounts) do
    double(active: [active_general_agency_account])
  end
  let(:active_general_agency_account) do
    instance_double(
      ::SponsoredBenefits::Accounts::GeneralAgencyAccount,
      benefit_sponsrship_general_agency_profile_id: general_agency_profile_id
    )
  end

  it "allows hbx_staff" do
    @is_hbx_staff = true
    expect(subject.view_proposals?).to be_truthy
  end

  it "rejects a user with no person" do
    expect(subject.view_proposals?).to be_falsey
  end

  it "rejects a user with no active and matching broker, broker staff, or general agency staff roles" do
    @person = person_with_no_roles
    expect(subject.view_proposals?).to be_falsey
  end

  it "accepts a user with a matching active broker role" do
    @person = person_with_matching_broker_role
    @owner_profile_id = broker_agency_profile_id
    expect(subject.view_proposals?).to be_truthy
  end

  it "accepts a user with a matching active broker staff role" do
    @person = person_with_matching_broker_staff_role
    @owner_profile_id = broker_agency_profile_id
    expect(subject.view_proposals?).to be_truthy
  end

  it "accepts a user with a matching active general agency staff role" do
    @person = person_with_matching_ga_staff_role
    allow(plan_design_organization).to receive(:general_agency_accounts).and_return(general_agency_accounts)
    expect(subject.view_proposals?).to be_truthy
  end
end

RSpec.describe SponsoredBenefits::PlanDesignOrganizationPolicy, "authorizing #can_access_employers_tab_via_ga_portal?" do
  let(:general_agency_profile_id) { "SOME GA PROFILE ID" }
  let(:current_user) { instance_double(User, has_hbx_staff_role?: @is_hbx_staff, person: @person) }
  let(:general_agency_profile) { instance_double(::BenefitSponsors::Organizations::GeneralAgencyProfile, id: general_agency_profile_id) }
  let(:subject) { described_class.new(current_user, general_agency_profile) }
  let(:matching_staff_role) do
    instance_double(
      GeneralAgencyStaffRole,
      benefit_sponsors_general_agency_profile_id: general_agency_profile_id
    )
  end
  let(:invalid_staff_role) do
    instance_double(
      GeneralAgencyStaffRole,
      benefit_sponsors_general_agency_profile_id: "A BOGUS OTHER GA PROFILE ID"
    )
  end
  let(:person_with_matching_roles) do
    instance_double(
      Person,
      active_general_agency_staff_roles: [matching_staff_role]
    )
  end
  let(:person_with_no_matching_roles) do
    instance_double(
      Person,
      active_general_agency_staff_roles: [invalid_staff_role]
    )
  end

  it "allows hbx_staff" do
    @is_hbx_staff = true
    expect(subject.can_access_employers_tab_via_ga_portal?).to be_truthy
  end

  it "rejects a user with no person" do
    expect(subject.can_access_employers_tab_via_ga_portal?).to be_falsey
  end

  it "rejects a user with no active and matching general agency staff roles" do
    @person = person_with_no_matching_roles
    expect(subject.can_access_employers_tab_via_ga_portal?).to be_falsey
  end

  it "accepts a user with a matching active general agency staff role" do
    @person = person_with_matching_roles
    expect(subject.can_access_employers_tab_via_ga_portal?).to be_truthy
  end
end