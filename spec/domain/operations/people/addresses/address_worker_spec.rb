# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AddressWorker, :dbclean => :after_each do
  let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:params) do
    person.addresses.first.delete
    {"person_hbx_id" => person.hbx_id, "address_id" => person.home_address.id}
  end

  it "should respond to #perform" do
  end

  context "for valid params" do
    it "should enqueue address compare job" do
    end
  end
end