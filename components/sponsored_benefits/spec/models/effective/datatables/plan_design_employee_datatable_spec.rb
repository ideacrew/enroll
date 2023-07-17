# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Effective::Datatables::PlanDesignEmployeeDatatable, "performing authorization" do
  let(:sponsorship_id) { "SOME SPONSORSHIP ID" }
  let(:access_policy) { instance_double(SponsoredBenefits::PlanDesignOrganizationPolicy) }
  let(:proposal_organization) { instance_double(SponsoredBenefits::Organizations::PlanDesignOrganization) }
  let(:benefit_sponsorship) { instance_double(SponsoredBenefits::BenefitSponsorships::BenefitSponsorship, plan_design_organization: proposal_organization) }
  let(:user) { instance_double(User) }

  subject { described_class.new({ id: sponsorship_id, profile_id: 'profile_id' }) }

  before :each do
    allow(SponsoredBenefits::BenefitSponsorships::BenefitSponsorship).to receive(:find).with(sponsorship_id).and_return(benefit_sponsorship)
    allow(::SponsoredBenefits::PlanDesignOrganizationPolicy).to receive(:new).with(user, proposal_organization).and_return(access_policy)
  end

  it "accepts authorized users" do
    allow(access_policy).to receive(:view_employees?).and_return(true)
    expect(subject.authorized?(user, nil, nil, nil)).to be_truthy
  end

  it "rejects unauthorized users" do
    allow(access_policy).to receive(:view_employees?).and_return(false)
    expect(subject.authorized?(user, nil, nil, nil)).to be_falsey
  end
end
