# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxHouseholdEnrollment, type: :model do
  it { is_expected.to have_attributes(group_ehb_premium: nil) }

  describe "for reinstated enrollment" do
    let!(:site_key) { EnrollRegistry[:enroll_app].setting(:site_key).item.upcase }
    let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
    let!(:family)        { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person) }
    let!(:person)       { FactoryBot.create(:person, :with_consumer_role) }
    let!(:address) { family.primary_person.rating_address }
    let!(:effective_date) { TimeKeeper.date_of_record.beginning_of_year }
    let!(:application_period) { effective_date.beginning_of_year..effective_date.end_of_year }
    let!(:rating_area) do
      ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: effective_date) || FactoryBot.create_default(:benefit_markets_locations_rating_area, active_year: effective_date.year)
    end
    let!(:service_area) do
      ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: effective_date).first || FactoryBot.create_default(:benefit_markets_locations_service_area, active_year: effective_date.year)
    end

    let!(:product) do
      prod =
        FactoryBot.create(
          :benefit_markets_products_health_products_health_product,
          :with_issuer_profile,
          :silver,
          benefit_market_kind: :aca_individual,
          kind: :health,
          application_period: application_period,
          service_area: service_area,
          csr_variant_id: '01'
        )
      prod.premium_tables = [premium_table]
      prod.save
      prod
    end

    let!(:premium_table)        { build(:benefit_markets_products_premium_table, effective_period: application_period, rating_area: rating_area) }
    let!(:tax_household_group) do
      family.tax_household_groups.create!(
        assistance_year: TimeKeeper.date_of_record.year,
        source: 'Admin',
        start_on: TimeKeeper.date_of_record.beginning_of_year,
        tax_households: [
          FactoryBot.build(:tax_household, household: family.active_household)
        ]
      )
    end

    let!(:tax_household) do
      tax_household_group.tax_households.first
    end
    let(:dependents) { family.dependents }
    let(:hbx_en_members) do
      dependents.collect do |dependent|
        FactoryBot.build(:hbx_enrollment_member, applicant_id: dependent.id)
      end
    end

    let(:reinstate_hbx_en_members) do
      dependents.collect do |dependent|
        FactoryBot.build(:hbx_enrollment_member, applicant_id: dependent.id)
      end
    end

    let!(:enrollment) do
      FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :individual_assisted, family: family, product: product, consumer_role_id: person.consumer_role.id, rating_area_id: rating_area.id, hbx_enrollment_members: hbx_en_members)
    end
    let!(:reinstate_enrollment) {FactoryBot.create(:hbx_enrollment, :individual_assisted, family: family, product: product, consumer_role_id: person.consumer_role.id, rating_area_id: rating_area.id, hbx_enrollment_members: reinstate_hbx_en_members)}
    let!(:thhm_enrollment_members) do
      enrollment.hbx_enrollment_members.collect do |member|
        FactoryBot.build(:tax_household_member_enrollment_member, hbx_enrollment_member_id: member.id, family_member_id: member.applicant_id, tax_household_member_id: "123")
      end
    end

    let!(:thhe) do
      tax_household_enrollment = FactoryBot.build(:tax_household_enrollment, enrollment_id: enrollment.id, tax_household_id: tax_household.id,
                                                                             health_product_hios_id: enrollment.product.hios_id,
                                                                             dental_product_hios_id: nil, tax_household_members_enrollment_members: thhm_enrollment_members)
      tax_household_enrollment.save
      tax_household_enrollment
    end

    context "#copy" do
      it 'should return attributes hash when type is :attributes' do
        expect(thhe.copy_attributes.class).to be Hash
      end
    end

    context "#build_tax_household_enrollment_for" do
      before do
        @new_thhe = thhe.build_tax_household_enrollment_for(reinstate_enrollment)
      end
      it 'should build new thhe' do
        expect(@new_thhe.id).not_to be thhe.id
      end

      it 'should not match enrollment_id with previous enrollment id' do

        expect(@new_thhe.enrollment_id).not_to be thhe.enrollment_id
      end

      it 'should not match hbx_enrollment_member_id with previous enrollment_member id' do
        expect(@new_thhe.tax_household_members_enrollment_members.first.hbx_enrollment_member_id).not_to be thhm_enrollment_members.first.hbx_enrollment_member_id
      end

      it 'should match family_member_id with previous enrollment - family member id' do
        expect(@new_thhe.tax_household_members_enrollment_members.first.family_member_id).to be thhm_enrollment_members.first.family_member_id
      end
    end
  end
end
