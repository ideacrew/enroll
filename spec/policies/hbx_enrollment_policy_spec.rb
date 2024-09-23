# frozen_string_literal: true

require "rails_helper"

describe HbxEnrollmentPolicy, "#pay_now?" do
  RSpec.shared_examples_for "an HbxEnrollmentPolicy given a user with a needed permission" do |check|
    before :each do
      perm_list = [
        :individual_market_primary_family_member?,
        :active_associated_individual_market_family_broker_staff?,
        :active_associated_individual_market_family_broker?,
        :coverall_market_primary_family_member?,
        :active_associated_coverall_market_family_broker?,
        :staff_can_access_pay_now?
      ]
      allow(subject).to receive(check.to_sym).and_return(true)
      (perm_list - [check].compact).each do |perm|
        allow(subject).to receive(perm.to_sym).and_return(false)
      end
    end

    it "has the ability to #{check} and can pay_now on an IVL enrollment" do
      allow(record).to receive(:is_shop?).and_return(false)
      expect(subject.pay_now?).to be_truthy
    end

    it "has the ability to #{check} but can't pay_now on a shop enrollment" do
      allow(record).to receive(:is_shop?).and_return(true)
      expect(subject.pay_now?).to be_falsey
    end
  end

  let(:user) { instance_double(User, :person => nil, :identity_verified? => true) }
  let(:record) { instance_double(HbxEnrollment, :is_shop? => true, :family => family) }
  let(:family) { instance_double(Family) }

  subject { described_class.new(user, record) }

  it "can't pay_now without permissions on an IVL enrollment" do
    allow(record).to receive(:is_shop?).and_return(false)
    expect(subject.pay_now?).to be_falsey
  end

  it_behaves_like "an HbxEnrollmentPolicy given a user with a needed permission", :individual_market_primary_family_member?
end