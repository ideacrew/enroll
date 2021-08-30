# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Operations::Families::PublishFamily, type: :model, dbclean: :after_each do
  let!(:person) {FactoryBot.create(:person)}
  let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:dependent_person) { FactoryBot.create(:person) }
  let(:dependent_family_member) do
    FamilyMember.new(is_primary_applicant: false, is_consent_applicant: false, person: dependent_person)
  end
  let!(:household) {FactoryBot.create(:household, family: family)}
  let!(:tax_household) {FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(2020, 1, 1), effective_ending_on: nil, is_eligibility_determined: true)}
  let!(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household, csr_percent_as_integer: 10)}

  before :all do
    DatabaseCleaner.clean
  end

  context 'publish payload to CRM' do
    before do
      family.family_members << dependent_family_member
    end

    it 'should return success with correct family information' do
      expect(subject.call(family)).to be_a(Dry::Monads::Result::Success)
    end
  end
end
