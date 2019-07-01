# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/spec/shared_contexts/enrollment.rb"

RSpec.describe Services::IvlRenewalService, type: :model do

  before :all do
    DatabaseCleaner.clean
  end

  context "Assisted enrollment" do
    include_context "setup families enrollments"

    let!(:renewal_enrollment_assisted) do
      FactoryBot.create(:hbx_enrollment, :individual_assisted, :with_enrollment_members,
                        consumer_role_id: family_assisted.primary_family_member.person.consumer_role.id,
                        effective_on: renewal_calender_date,
                        household: family_assisted.active_household,
                        enrollment_members: [family_assisted.family_members.first],
                        product: renewal_csr_87_product)
    end

    subject do
      eligibility_service = Services::IvlRenewalService.new(renewal_enrollment_assisted)
      eligibility_service.process
      eligibility_service
    end

    let(:aptc_values) do
      { applied_percentage: 87,
        applied_aptc: 150,
        csr_amt: 87,
        max_aptc: 200 }
    end

    before do
      hbx_profile.benefit_sponsorship.benefit_coverage_periods.each do |bcp|
        slcsp_id = if bcp.start_on.year == renewal_csr_87_product.application_period.min.year
                     renewal_csr_87_product.id
                   else
                     active_csr_87_product.id
                   end
        bcp.update_attributes!(slcsp_id: slcsp_id)
      end

      # hbx_profile.save!
      hbx_profile.reload

      family_assisted.active_household.reload
      family_assisted.primary_family_member.person.update_attributes(dob: (Time.zone.today - 45.years))
      family_assisted.reload
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) {|_id, _start, age| age * 1.0}
    end

    it "should process and return available aptc/csr" do
      expect(subject.available_aptc).not_to eq nil
    end

    it "should append APTC values" do
      renewel_enrollment = subject.assign(aptc_values)
      expect(renewel_enrollment.applied_aptc_amount.to_f.round).to eq((renewel_enrollment.total_premium * renewel_enrollment.product.ehb).round)
    end

    it "should get min on given applied, ehb premium and available aptc" do
      expect(subject.calculate_applied_aptc(aptc_values).nil?).to eq false
    end

    it "should return tax_household members" do
      expect(subject.find_tax_household_members).to eq tax_household.tax_household_members
    end
  end
end