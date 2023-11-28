# frozen_string_literal: true

require "rails_helper"

describe Effective::Datatables::GeneralAgencyFamilyDataTable, "with correct access permissions" do
  let(:general_agency_profile_id) { "SOME BOGUS ID" }
  let(:current_user) { instance_double(User) }
  let(:general_agency_profile) { instance_double(GeneralAgencyProfile) }
  let(:access_policy) { instance_double(AccessPolicies::GeneralAgencyProfile) }

  before :each do
    allow(GeneralAgencyProfile).to receive(:find).with(general_agency_profile_id).and_return(general_agency_profile)
    allow(AccessPolicies::GeneralAgencyProfile).to receive(:new).with(current_user).and_return(access_policy)
  end

  it "allows authorized users" do
    allow(access_policy).to receive(:view_families).with(general_agency_profile).and_return true
    datatable = Effective::Datatables::GeneralAgencyFamilyDataTable.new({id: general_agency_profile_id})
    expect(datatable.authorized?(current_user, nil, nil, nil)).to be_truthy
  end

  it "denies unauthorized users" do
    allow(access_policy).to receive(:view_families).with(general_agency_profile).and_return false
    datatable = Effective::Datatables::GeneralAgencyFamilyDataTable.new({id: general_agency_profile_id})
    expect(datatable.authorized?(current_user, nil, nil, nil)).to be_falsey
  end
end