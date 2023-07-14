# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Effective::Datatables::BenefitSponsorsGeneralAgencyDataTable, "verifying access" do
  let(:general_agency) do
    FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, :with_site)
  end
  let(:general_agency_profile) { general_agency.general_agency_profile }
  let(:general_agency_profile_id) { general_agency_profile.id }
  let(:current_user) { instance_double(User) }
  let(:access_policy) { instance_double(::BenefitSponsors::Organizations::GeneralAgencyProfilePolicy) }

  before :each do
    allow(
      BenefitSponsors::Organizations::GeneralAgencyProfilePolicy
    ).to receive(:new).with(current_user, general_agency_profile).and_return(access_policy)
  end

  it "allows authorized users" do
    allow(access_policy).to receive(:employers?).and_return true
    datatable = Effective::Datatables::BenefitSponsorsGeneralAgencyDataTable.new({id: general_agency_profile_id})
    expect(datatable.authorized?(current_user, nil, nil, nil)).to be_truthy
  end

  it "denies unauthorized users" do
    allow(access_policy).to receive(:employers?).and_return false
    datatable = Effective::Datatables::BenefitSponsorsGeneralAgencyDataTable.new({id: general_agency_profile_id})
    expect(datatable.authorized?(current_user, nil, nil, nil)).to be_falsey
  end
end
