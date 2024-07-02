# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Private::PersonSaved, dbclean: :after_each do

  let!(:person) { FactoryBot.create(:person, :with_ssn) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:dependent) { FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 30.years) }


  describe 'Success' do
     let(:changed_attributes) { {changed_person_attributes: {first_name: 'John', last_name: "Fitz", encrypted_ssn: 'New Encrypted SSN', dob: TimeKeeper.date_of_record - 20.years},
                                changed_address_attributes: [{kind: 'home', address_1: '123 Main St', city: 'Portland', state: 'ME', zip: '20001'}],
                                changed_phone_attributes: [{:kind => 'home',:full_phone_number=>"5555555557", :number=>"5555557", :updated_at=>TimeKeeper.date_of_record}],
                                changed_email_attributes: [{:kind=>"home", :address=>"test@test.com", :updated_at=>TimeKeeper.date_of_record}],
                                changed_relationship_attributes: [{:kind=>'child', :relative_id=>dependent.id, :updated_at=>nil}] }}
    let(:subject) { ::Operations::Private::PersonSaved.new }
    let(:params) { {changed_attributes: changed_attributes, after_save_version: person.to_hash} }
    let(:headers) {{after_updated_at: person.updated_at, before_updated_at: person.updated_at - 1.second}}
    
    it 'returns success' do
      result = described_class.new.call(headers:headers, params: params)

      expect(result.success?). to be_truthy
    end

    it 'returns success' do
      result = described_class.new.call(headers:headers, params: params)
      expect(result.success). to eql("Successfully published 'events.families.created_or_updated' for person with hbx_id: #{person.hbx_id}")
    end
  end

  #! DONE: check build family determination
  #! Done check for updates to first name
  #! Done check for updates to relationships
  # Check for updates to addresses

  # check application updates for addresses,phones, emails
  # build specs in person.rb

  describe 'Failure' do
    
    it 'returns failure' do
      result = described_class.new.call(headers: {}, params: {})

      expect(result.failure?). to be_truthy
    end
  end
end
