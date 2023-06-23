# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::People::Addresses::Compare, dbclean: :after_each do
  let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:params) do
    person.addresses.first.delete
    {:person_hbx_id => person.hbx_id, :address_id => person.home_address.id}
  end

  context 'when valid params passed' do
    it 'should return success' do
      person.home_address.update_attributes(state: "ME")
      result = subject.call(params)
      expect(result.success?).to be_truthy
    end
  end

  context 'when invalid params passed' do
    it 'should return success' do
      person.home_address.update_attributes(state: "ME")
      result = subject.call({})
      expect(result.failure?).to be_truthy
    end
  end
end
