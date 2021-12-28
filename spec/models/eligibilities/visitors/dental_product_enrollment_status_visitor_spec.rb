# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::Eligibilities::Visitors::DentalProductEnrollmentStatusVisitor,
               type: :model,
               dbclean: :after_each do
  let!(:person1) do
    FactoryBot.create(
      :person,
      :with_consumer_role,
      :with_active_consumer_role,
      first_name: 'test10',
      last_name: 'test30',
      gender: 'male'
    )
  end

  let!(:person2) do
    person =
      FactoryBot.create(
        :person,
        :with_consumer_role,
        :with_active_consumer_role,
        first_name: 'test',
        last_name: 'test10',
        gender: 'male'
      )
    person1.ensure_relationship_with(person, 'child')
    person
  end

  let!(:family) do
    FactoryBot.create(:family, :with_primary_family_member, person: person1)
  end

  let!(:family_member) do
    FactoryBot.create(:family_member, family: family, person: person2)
  end

  let(:household) { FactoryBot.create(:household, family: family) }
#   let!(:organization) do
#     FactoryBot.create(:organization, legal_name: 'CareFirst', dba: 'care')
#   end
#   let!(:carrier_profile1) do
#     FactoryBot.create(:benefit_sponsors_organizations_issuer_profile)
#   end
#   let!(:product1) do
#     FactoryBot.create(
#       :benefit_markets_products_health_products_health_product,
#       benefit_market_kind: :aca_individual,
#       kind: :dental,
#       csr_variant_id: '01'
#     )
#   end
  let!(:dental_product) { FactoryBot.create(:benefit_markets_products_dental_products_dental_product, :with_issuer_profile) }

  let!(:hbx_enrollment1) do
    FactoryBot.create(
      :hbx_enrollment,
      :with_enrollment_members,
      enrollment_members: family.family_members,
      kind: 'individual',
      product: dental_product,
      household: family.latest_household,
      effective_on: TimeKeeper.date_of_record.beginning_of_year,
      enrollment_kind: 'open_enrollment',
      family: family,
      aasm_state: 'coverage_selected',
      consumer_role: person1.consumer_role,
      enrollment_signature: true,
      coverage_kind: 'dental'
    )
  end

  let(:subject_ref) { family_member.to_global_id }

  let(:eligibility_item) do
    Operations::EligibilityItems::Find
      .new
      .call(eligibility_item_key: :dental_product_enrollment_status)
      .success
  end

  let(:effective_date) { Date.today }

  let(:evidence_item) { eligibility_item.evidence_items.first }

  subject do
    visitor = described_class.new
    visitor.subject = family.primary_applicant
    visitor.evidence_item = evidence_item
    visitor.effective_date = effective_date
    visitor
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'when required params passed' do
    it 'should successfully build evidence state' do
      subject.call
      expect(subject.evidence).to be_a(Hash)
    end

    it 'should build evidence state for the given eligibility item' do
      subject.call
      expect(subject.evidence.key?(evidence_item.key.to_sym)).to be_truthy
    end
  end
end
