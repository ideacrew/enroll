# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Effective::Datatables::BrokerAgencyPlanDesignOrganizationDatatable, "authorizing access" do
  let(:broker_agency_profile_id) { BSON::ObjectId.new }
  let(:broker_agency_profile) { instance_double(BenefitSponsors::Organizations::BrokerAgencyProfile, id: broker_agency_profile_id) }
  let(:user) { instance_double(User) }
  let(:access_policy) { instance_double(::SponsoredBenefits::BrokerAgencyPlanDesignOrganizationPolicy) }

  before :each do
    allow(BenefitSponsors::Organizations::BrokerAgencyProfile).to receive(:find).with(broker_agency_profile_id).and_return(broker_agency_profile)
    allow(::SponsoredBenefits::BrokerAgencyPlanDesignOrganizationPolicy).to receive(:new).with(user, broker_agency_profile).and_return(access_policy)
  end

  it "accepts authorized users" do
    allow(access_policy).to receive(:manage_quotes?).and_return(true)
    datatable = Effective::Datatables::BrokerAgencyPlanDesignOrganizationDatatable.new({profile_id: broker_agency_profile_id})
    expect(datatable.authorized?(user, nil, nil, nil)).to be_truthy
  end

  it "rejects unauthorized users" do
    allow(access_policy).to receive(:manage_quotes?).and_return(false)
    datatable = Effective::Datatables::BrokerAgencyPlanDesignOrganizationDatatable.new({profile_id: broker_agency_profile_id})
    expect(datatable.authorized?(user, nil, nil, nil)).to be_falsey
  end
end
