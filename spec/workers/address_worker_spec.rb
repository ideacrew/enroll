# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe AddressWorker, type: :worker, :dbclean => :after_each do
  let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:params) do
    person.addresses.first.delete
    {"person_hbx_id" => person.hbx_id, "address_id" => person.home_address.id}
  end

  it "should respond to #perform" do
    expect(AddressWorker.new).to respond_to(:perform)
  end

  context "for valid params" do
    it "should enqueue address compare job" do
      AddressWorker.clear
      expect(AddressWorker.jobs.size).to eq 0
      AddressWorker.perform_async(params)
      expect(AddressWorker.jobs.size).to eq 1
      AddressWorker.clear
    end
  end
end