# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Operations::Families::PublishFamily, type: :model, dbclean: :after_each do
  let!(:person) {FactoryBot.create(:person, :with_consumer_role)}
  let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:dependent_person) { FactoryBot.create(:person, :with_consumer_role) }
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
      person.person_relationships << PersonRelationship.new(relative: person, kind: "self")
      person.person_relationships.build(relative: dependent_person, kind: "spouse")
      person.save!
      person.consumer_role.ridp_documents.first.update_attributes(uploaded_at: TimeKeeper.date_of_record)
      # person.consumer_role.verification_types.each {|vt| vt.update_attributes(validation_status: 'outstanding', due_date: TimeKeeper.date_of_record - 1.day)}
      # dependent_person.person_relationships << PersonRelationship.new(relative: dependent_person, kind: "self")
      family.family_members.each do |fm|
        # Delete phones with extensions due to factory
        fm.person.phones.destroy_all
        fm.person.phones << Phone.new(
          kind: 'home', country_code: '',
          area_code: '202', number: '1030404',
          extension: '', primary: nil,
          full_phone_number: '2021030404'
        )
      end
      family.save!
      family.family_members.each do |fm|
        family.households.first.coverage_households.first.coverage_household_members.build(family_member_id: fm.id).save! if family.households.first.coverage_households.first.coverage_household_members.where(family_member_id: fm.id).blank?
        # fm.person.consumer_role.ridp_documents << FactoryBot.build(:ridp_document, :ridp_verification_type => 'Identity')
        # fm.person.consumer_role.identity_validation = "valid"
        # fm.person.consumer_role.application_validation = "valid"
        # fm.person.save
      end
    end

    it 'should return success with correct family information' do
      expect(subject.call(family)).to be_a(Dry::Monads::Result::Success)
    end
  end
end
