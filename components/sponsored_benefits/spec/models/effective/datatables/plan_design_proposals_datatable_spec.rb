# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Effective::Datatables::PlanDesignProposalsDatatable, "performing authorization" do
  let(:profile_id) { BSON::ObjectId.new }
  let(:organization_id) { BSON::ObjectId.new }
  let(:access_policy) { instance_double(SponsoredBenefits::PlanDesignOrganizationPolicy) }
  let(:plan_design_organization) { instance_double(SponsoredBenefits::Organizations::PlanDesignOrganization, plan_design_proposals: []) }
  let(:user) { instance_double(User) }

  subject { described_class.new({ organization_id: organization_id, profile_id: profile_id }) }

  before :each do
    allow(SponsoredBenefits::Organizations::PlanDesignOrganization).to receive(:find).with(organization_id).and_return(plan_design_organization)
    allow(::SponsoredBenefits::PlanDesignOrganizationPolicy).to receive(:new).with(user, plan_design_organization).and_return(access_policy)
  end

  it "accepts authorized users" do
    allow(access_policy).to receive(:view_proposals?).and_return(true)
    expect(subject.authorized?(user, nil, nil, nil)).to be_truthy
  end

  it "rejects unauthorized users" do
    allow(access_policy).to receive(:view_proposals?).and_return(false)
    expect(subject.authorized?(user, nil, nil, nil)).to be_falsey
  end
end
