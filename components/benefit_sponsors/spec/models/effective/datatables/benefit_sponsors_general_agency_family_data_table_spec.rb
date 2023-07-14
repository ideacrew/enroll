# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Effective::Datatables::BenefitSponsorsGeneralAgencyFamilyDataTable, "verifying access" do
  let(:general_agency_profile_id) { BSON::ObjectId.new }
  let(:current_user) { instance_double(User) }
  let(:general_agency_profile) { instance_double(::BenefitSponsors::Organizations::GeneralAgencyProfile) }
  let(:access_policy) { instance_double(::BenefitSponsors::Organizations::GeneralAgencyProfilePolicy) }
  let(:general_agency_organization) { instance_double(::BenefitSponsors::Organizations::Organization, general_agency_profile: general_agency_profile) }

  before :each do
    allow(
      BenefitSponsors::Organizations::Organization
    ).to receive(:where).with(:"profiles._id" => general_agency_profile_id).and_return([general_agency_organization])

    allow(
      BenefitSponsors::Organizations::GeneralAgencyProfilePolicy
    ).to receive(:new).with(current_user, general_agency_profile).and_return(access_policy)
  end

  it "allows authorized users" do
    allow(access_policy).to receive(:families?).and_return true
    datatable = Effective::Datatables::BenefitSponsorsGeneralAgencyFamilyDataTable.new({id: general_agency_profile_id})
    expect(datatable.authorized?(current_user, nil, nil, nil)).to be_truthy
  end

  it "denies unauthorized users" do
    allow(access_policy).to receive(:families?).and_return false
    datatable = Effective::Datatables::BenefitSponsorsGeneralAgencyFamilyDataTable.new({id: general_agency_profile_id})
    expect(datatable.authorized?(current_user, nil, nil, nil)).to be_falsey
  end
end