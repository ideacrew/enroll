# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Private::PersonSaved, dbclean: :after_each do

  let!(:person) { FactoryBot.create(:person, :with_ssn) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

  describe 'person_saved' do
    let(:changed_attributes) { {first_name: 'Tom', last_name: "Fitz", encrypted_ssn: 'New Encrypted SSN'} }
    let(:subject) { ::Operations::Private::PersonSaved.new }
    let(:params) { {changed_attributes: changed_attributes, after_save_version: person.to_hash} }
    
    it 'should return Success' do
      result = subject.call(headers: nil, params: params)

      expect(result.success?). to be_truthy
    end
  end
end
