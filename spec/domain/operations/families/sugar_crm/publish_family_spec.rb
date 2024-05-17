# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Operations::Families::SugarCrm::PublishFamily, type: :model, dbclean: :after_each do
  include Dry::Monads[:do, :result]
  let(:person) {FactoryBot.create(:person, :with_consumer_role)}
  let(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:dependent_person) { FactoryBot.create(:person, :with_consumer_role) }
  let(:dependent_person2) { FactoryBot.create(:person) }
  let(:dependent_family_member) do
    FamilyMember.new(is_primary_applicant: false, is_consent_applicant: false, person: dependent_person)
  end
  let(:dependent_family_member2) do
    FamilyMember.new(is_primary_applicant: false, is_consent_applicant: false, person: dependent_person2)
  end
  let(:household) {FactoryBot.create(:household, family: family)}
  let(:tax_household) {FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(2020, 1, 1), effective_ending_on: nil, is_eligibility_determined: true)}
  let(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household, csr_percent_as_integer: 10)}

  before do
    # Test the CRM update in isolation
    allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
    allow(EnrollRegistry[:crm_update_family_save].feature).to receive(:is_enabled).and_return(false)
    DatabaseCleaner.clean
    family.family_members << dependent_family_member
    person.person_relationships << PersonRelationship.new(relative: person, kind: "self")
    person.person_relationships.build(relative: dependent_person, kind: "spouse")
    person.save!
    person.consumer_role.ridp_documents.first.update_attributes(uploaded_at: TimeKeeper.date_of_record)
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
    # Not yet called the publish, publish deactivated in this spec
    family.crm_notifiction_needed = false
    family.save!
    # Just to make the spec less complicated
    family.irs_groups.destroy_all
    # have to run save an extra time due to the encrytped ssn
    person.is_incarcerated = true
    person.save!
    dependent_person.is_incarcerated = true
    dependent_person.save!
    dependent_person2.is_incarcerated = true
    dependent_person2.save!
    person.set(crm_notifiction_needed: false)
    dependent_person.set(crm_notifiction_needed: false)
    dependent_person2.set(crm_notifiction_needed: false)
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:check_for_crm_updates).and_return(true)
  end

  context "failed application payload" do
    before do
      allow(::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application).to receive_message_chain('new.call').with(application).and_return(Dry::Monads::Result::Failure.new(application))
      # SSn of primary person is a critical attribute
      family.primary_person.ssn = "11122345"
      family.primary_person.save
      family.reload
    end

    let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: 'submitted', hbx_id: "830293", effective_date: DateTime.new(2021,1,1,4,5,6)) }
    let!(:applicant1) { FactoryBot.create(:financial_assistance_applicant, application: application, family_member_id: family.primary_person.id, is_primary_applicant: true, person_hbx_id: family.primary_person.hbx_id) }
    let!(:applicant2) { FactoryBot.create(:financial_assistance_applicant, application: application, family_member_id: family.family_members.second.id, person_hbx_id: family.family_members.second.person.hbx_id) }

    it 'should return failure' do
      expect(subject.call(family)).to be_a(Dry::Monads::Result::Failure)
    end
  end

  context "only publish payload to CRM if critical upates were made" do
    before do
      person.is_homeless = true
      person.save!
      person.run_callbacks(:before_save)
      family.reload
    end

    it "should return failure if no family members critical attributes have been changed" do
      expect(subject.call(family)).to eq(Failure("No critical changes made to family: #{family.id}, no update needed to CRM gateway."))
    end
  end

  context 'publish payload to CRM after first name changed' do

    it 'should return success' do
      # first name of primary person is a critical attribute
      family.primary_applicant.person.first_name = "newname"
      family.primary_applicant.person.save!
      family.reload
      expect(subject.call(family)).to be_a(Dry::Monads::Result::Success)
    end
  end

  context 'publish payload to CRM after family member added' do
    before do
      family.family_members << dependent_family_member2
      person.person_relationships.build(relative: dependent_person2, kind: "child")
      dependent_person2.save!
      family.reload
    end

    it 'should return success' do
      expect(subject.call(family)).to be_a(Dry::Monads::Result::Success)
    end
  end
end
