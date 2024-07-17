# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Fdsh::PayloadEligibility::CheckDeterminationSubjectEligibilityRules, dbclean: :after_each do
  let(:primary_dob){ Date.today - 57.years }


  let(:family) do
    FactoryBot.create(:family, :with_primary_family_member, :person => primary)
  end

  let(:spouse_person) { FactoryBot.create(:person, :with_consumer_role, dob: spouse_dob, ssn: 101011012) }
  let!(:spouse) { FactoryBot.create(:family_member, person: spouse_person, family: family) }
  let(:spouse_dob) { Date.today - 55.years }
  let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :with_issuer_profile, metal_level_kind: :silver, benefit_market_kind: :aca_individual) }
  let!(:enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      :with_enrollment_members,
                      family: family,
                      enrollment_members: family.family_members,
                      household: family.active_household,
                      coverage_kind: :health,
                      effective_on: Date.today,
                      kind: "individual",
                      product: product,
                      rating_area_id: primary.consumer_role.rating_address.id,
                      consumer_role_id: family.primary_person.consumer_role.id,
                      aasm_state: 'coverage_selected')
  end

  let(:cv3_family) { Operations::Transformers::FamilyTo::Cv3Family.new.call(family).success}
  let(:family_entity) { AcaEntities::Operations::CreateFamily.new.call(cv3_family).value! }

  before do
    allow(EnrollRegistry[:alive_status].feature).to receive(:is_enabled).and_return(true)
    primary.build_demographics_group
    spouse_person.build_demographics_group
    Operations::Eligibilities::BuildFamilyDetermination.new.call({ effective_date: Date.today, family: family })
  end

  context 'when all family members are eligible' do
    let(:primary) { FactoryBot.create(:person, :with_consumer_role, dob: primary_dob, ssn: 101011011) }
    let(:spouse_person) { FactoryBot.create(:person, :with_consumer_role, dob: spouse_dob, ssn: 101011012) }

    it 'should return success' do
      result = subject.call(family_entity.eligibility_determination.subjects.values.first, :alive_status)
      expect(result.success?).to be_truthy
    end
  end

  context 'when family member is not eligible' do
    let(:primary) { FactoryBot.create(:person, :with_consumer_role, dob: primary_dob, ssn: 101011011) }
    let(:spouse_person) { FactoryBot.create(:person, :with_consumer_role, dob: spouse_dob, ssn: nil) }

    it 'should return failure' do
      result = subject.call(family_entity.eligibility_determination.subjects.values[1], :alive_status)
      expect(result.failure?).to be_truthy
    end
  end
end