require 'rails_helper'
require File.join(Rails.root, 'spec/shared_contexts/ivl_eligibility')

RSpec.describe Factories::EligibilityFactory, type: :model, dbclean: :after_each do
  include_context 'setup two tax households with one ia member each'

  let!(:enrollment1) { FactoryBot.create(:hbx_enrollment, :individual_shopping, household: family.active_household) }
  let!(:enrollment_member1) { FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: enrollment1, applicant_id: family_member.id) }

  before :each do
    product = FactoryBot.create(:benefit_markets_products_health_products_health_product, metal_level_kind: :silver)
    benefit_sponsorship = FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period).benefit_sponsorship
    benefit_sponsorship.benefit_coverage_periods.each { |bcp| bcp.update_attributes!(slcsp_id: product.id) }
  end

  context 'for one member enrollment' do
    before :each do
      @eligibility_factory ||= described_class.new(enrollment1.id)
      @available_eligibility ||= @eligibility_factory.fetch_available_eligibility
    end

    it 'should return a Hash' do
      expect(@available_eligibility.class).to eq Hash
    end

    [:aptc, :csr, :total_available_aptc].each do |keyy|
      it { expect(@available_eligibility.key?(keyy)).to be_truthy }
    end

    it 'should have all the aptc shopping member ids' do
      aptc_keys = @available_eligibility[:aptc].keys
      enrollment1.hbx_enrollment_members.map(&:applicant_id).each do |member_id|
        expect(aptc_keys).to include(member_id.to_s)
      end
    end

    it { expect(@available_eligibility[:aptc]["#{family_member.id.to_s}"]).to eq 100.00 }
    it { expect(@available_eligibility[:total_available_aptc]).to eq 100.00 }
    it { expect(@available_eligibility[:csr]).to eq 'csr_87' }
  end

  context 'for two members enrollment from two tax households' do
    let!(:enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, is_subscriber: false, hbx_enrollment: enrollment1, applicant_id: family_member2.id) }

    before :each do
      @eligibility_factory ||= described_class.new(enrollment1.id)
      @available_eligibility ||= @eligibility_factory.fetch_available_eligibility
    end

    it 'should return a Hash' do
      expect(@available_eligibility.class).to eq Hash
    end

    [:aptc, :csr, :total_available_aptc].each do |keyy|
      it { expect(@available_eligibility.key?(keyy)).to be_truthy }
    end

    it 'should have all the aptc shopping member ids' do
      aptc_keys = @available_eligibility[:aptc].keys
      enrollment1.hbx_enrollment_members.map(&:applicant_id).each do |member_id|
        expect(aptc_keys).to include(member_id.to_s)
      end
    end

    it { expect(@available_eligibility[:aptc][family_member.id.to_s]).to eq 100.00 }
    it { expect(@available_eligibility[:aptc][family_member2.id.to_s]).to eq 200.0 }
    it { expect(@available_eligibility[:total_available_aptc]).to eq 300.00 }
    it { expect(@available_eligibility[:csr]).to eq 'csr_87' }
  end

  context 'for two members enrollment from two tax households with one medicaid member' do
    let!(:enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, is_subscriber: false, hbx_enrollment: enrollment1, applicant_id: family_member2.id) }

    before :each do
      tax_household_member.update_attributes!(is_ia_eligible: false, is_medicaid_chip_eligible: true)
      @eligibility_factory ||= described_class.new(enrollment1.id)
      @available_eligibility ||= @eligibility_factory.fetch_available_eligibility
    end

    it 'should return a Hash' do
      expect(@available_eligibility.class).to eq Hash
    end

    [:aptc, :csr, :total_available_aptc].each do |keyy|
      it { expect(@available_eligibility.key?(keyy)).to be_truthy }
    end

    it { expect(@available_eligibility[:aptc][family_member.id.to_s]).to eq 100.00 }
    it { expect(@available_eligibility[:total_available_aptc]).to eq 100.00 }
    it { expect(@available_eligibility[:csr]).to eq 'csr_100' }
  end

  context 'with an existing enrollment' do
    let!(:enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, is_subscriber: false, hbx_enrollment: enrollment1, applicant_id: family_member2.id) }
    let!(:enrollment2) { FactoryBot.create(:hbx_enrollment, :individual_assisted, applied_aptc_amount: 50.00, household: family.active_household) }
    let!(:enrollment_member21) { FactoryBot.create(:hbx_enrollment_member, hbx_enrollment: enrollment2, applicant_id: family_member.id, applied_aptc_amount: 50.00) }

    before :each do
      @eligibility_factory ||= described_class.new(enrollment1.id)
      @available_eligibility ||= @eligibility_factory.fetch_available_eligibility
    end

    it 'should return a Hash' do
      expect(@available_eligibility.class).to eq Hash
    end

    [:aptc, :csr, :total_available_aptc].each do |keyy|
      it { expect(@available_eligibility.key?(keyy)).to be_truthy }
    end

    it 'should have all the aptc shopping member ids' do
      aptc_keys = @available_eligibility[:aptc].keys
      enrollment1.hbx_enrollment_members.map(&:applicant_id).each do |member_id|
        expect(aptc_keys).to include(member_id.to_s)
      end
    end

    it { expect(@available_eligibility[:aptc][family_member.id.to_s]).to eq 50.00 }
    it { expect(@available_eligibility[:aptc][family_member2.id.to_s]).to eq 200.0 }
    it { expect(@available_eligibility[:total_available_aptc]).to eq 250.00 }
    it { expect(@available_eligibility[:csr]).to eq 'csr_87' }
  end
end
