# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::Eligibilities::Visitors::AcaIndividualMarketEligibilityVisitor,
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

  let(:subject_ref) { family_member.to_global_id }

  let(:eligibility_item) do
    Operations::EligibilityItems::Find
      .new
      .call(eligibility_item_key: :aca_individual_market_eligibility)
      .success
  end

  let(:effective_date) { Date.today }
  let(:subjects) { family.family_members.map(&:to_global_id) }

  let(:required_params) do
    {
      subject: family_member.to_global_id,
      effective_date: effective_date,
      eligibility_item: eligibility_item
    }
  end

  let(:evidence_item) { eligibility_item.evidence_items[1] }

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
