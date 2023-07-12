# frozen_string_literal: true

require 'rails_helper'

describe Effective::Datatables::EmployeeDatatable, "performing authorization" do
  let(:employer_profile) { instance_double(BenefitSponsors::Organizations::FehbEmployerProfile) }
  let(:organization) { instance_double(::BenefitSponsors::Organizations::Organization, employer_profile: employer_profile)}
  let(:employer_profile_id) { BSON::ObjectId.new.to_s }
  let(:access_policy) { instance_double(::BenefitSponsors::EmployerProfilePolicy) }
  let(:user) { instance_double(User) }
  let(:employer_profile_query_proxy) { double }

  before :each do
    allow(::BenefitSponsors::EmployerProfilePolicy).to receive(:new).with(user, employer_profile).and_return(access_policy)
    allow(::BenefitSponsors::Organizations::Organization).to receive(:employer_profiles).and_return(employer_profile_query_proxy)
    allow(employer_profile_query_proxy).to receive(:where).with(
      {
        :"profiles._id" => BSON::ObjectId.from_string(employer_profile_id)
      }
    ).and_return([organization])
  end

  it "allows an authorized user" do
    allow(access_policy).to receive(:show?).and_return(true)
    datatable = Effective::Datatables::EmployeeDatatable.new({id: employer_profile_id})
    expect(datatable.authorized?(user, nil, nil, nil)).to be_truthy
  end

  it "rejects an unauthorized user" do
    allow(access_policy).to receive(:show?).and_return(false)
    datatable = Effective::Datatables::EmployeeDatatable.new({id: employer_profile_id})
    expect(datatable.authorized?(user, nil, nil, nil)).to be_falsey
  end
end
