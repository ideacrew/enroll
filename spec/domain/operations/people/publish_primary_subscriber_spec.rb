# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Operations::People::SugarCrm::PublishPrimarySubscriber, type: :model, dbclean: :after_each do
  let!(:person) do
    # Some of these attributes are necessary in the person entity
    FactoryBot.create(
      :person,
      :with_consumer_role,
      is_disabled: false,
      no_dc_address: false,
      is_homeless: false
    )
  end
  let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}

  before :all do
    DatabaseCleaner.clean
  end

  context 'publish payload to CRM' do
    before do
      fm = family.family_members.first
      fm.person.phones.destroy_all
      fm.person.phones << Phone.new(
        kind: 'home', country_code: '',
        area_code: '202', number: '1030404',
        extension: '', primary: nil,
        full_phone_number: '2021030404'
      )
      family.save!
    end

    it 'should return success with correct primary subscriber person validation for publishing' do
      expect(subject.call(person)).to be_a(Dry::Monads::Result::Success)
    end
  end
end
