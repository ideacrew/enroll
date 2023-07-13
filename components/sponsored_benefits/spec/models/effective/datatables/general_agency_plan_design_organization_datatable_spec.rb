# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Effective::Datatables::GeneralAgencyPlanDesignOrganizationDatatable, "performing authorization" do
  let(:general_agency_id) { "GENERAL AGENCY ID" }
  let(:access_policy) { instance_double(SponsoredBenefits::PlanDesignOrganizationPolicy) }
  let(:general_agency) { instance_double(::BenefitSponsors::Organizations::GeneralAgencyProfile) }
  let(:user) { instance_double(User) }

  subject { described_class.new({profile_id: general_agency_id }) }

  before :each do
    allow(::BenefitSponsors::Organizations::GeneralAgencyProfile).to receive(:find).with(general_agency_id).and_return(general_agency)
    allow(::SponsoredBenefits::PlanDesignOrganizationPolicy).to receive(:new).with(user, general_agency).and_return(access_policy)
  end

  it "accepts authorized users" do
    allow(access_policy).to receive(:can_access_employers_tab_via_ga_portal?).and_return(true)
    expect(subject.authorized?(user, nil, nil, nil)).to be_truthy
  end

  it "rejects unauthorized users" do
    allow(access_policy).to receive(:can_access_employers_tab_via_ga_portal?).and_return(false)
    expect(subject.authorized?(user, nil, nil, nil)).to be_falsey
  end
end
