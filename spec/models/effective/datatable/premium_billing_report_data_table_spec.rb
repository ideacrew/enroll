# frozen_string_literal: true

require "rails_helper"

describe Effective::Datatables::PremiumBillingReportDataTable, "with correct access permissions" do
  let(:employer_profile_id) { "SOME BOGUS PROFILE ID" }
  let(:billing_date) { "06/21/2020" }
  let(:current_user) { instance_double(User) }

  let(:access_policy) { instance_double(EmployerProfilePolicy) }

  let(:filter_attributes) do
    {
      id: employer_profile_id,
      billing_date: billing_date
    }
  end

  let(:billing_date_as_date) { Date.strptime(billing_date, "%m/%d/%Y") }

  before :each do
    allow(EmployerProfilePolicy).to receive(:new).with(current_user, employer_profile).and_return(access_policy)
    allow(Queries::EmployerPremiumStatement).to receive(:new).with(employer_profile, billing_date_as_date).and_return([])
  end

  context "for a legacy employer profile" do
    let(:employer_profile) { instance_double(EmployerProfile) }

    before :each do
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
    end

    it "allows authorized users" do
      allow(access_policy).to receive(:list_enrollments?).and_return true
      datatable = Effective::Datatables::PremiumBillingReportDataTable.new(filter_attributes)
      expect(datatable.authorized?(current_user, nil, nil, nil)).to be_truthy
    end

    it "denies unauthorized users" do
      allow(access_policy).to receive(:list_enrollments?).and_return false
      datatable = Effective::Datatables::PremiumBillingReportDataTable.new(filter_attributes)
      expect(datatable.authorized?(current_user, nil, nil, nil)).to be_falsey
    end
  end

  context "for a benefit sponsors employer profile" do
    let(:employer_profile) { instance_double(BenefitSponsors::Organizations::FehbEmployerProfile) }

    before :each do
      allow(EmployerProfile).to receive(:find).with(employer_profile_id).and_return(nil)
      allow(BenefitSponsors::Organizations::Profile).to receive(:find).with(employer_profile_id).and_return(employer_profile)
    end

    it "allows authorized users" do
      allow(access_policy).to receive(:list_enrollments?).and_return true
      datatable = Effective::Datatables::PremiumBillingReportDataTable.new(filter_attributes)
      expect(datatable.authorized?(current_user, nil, nil, nil)).to be_truthy
    end

    it "denies unauthorized users" do
      allow(access_policy).to receive(:list_enrollments?).and_return false
      datatable = Effective::Datatables::PremiumBillingReportDataTable.new(filter_attributes)
      expect(datatable.authorized?(current_user, nil, nil, nil)).to be_falsey
    end
  end
end