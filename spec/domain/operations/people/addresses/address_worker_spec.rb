# frozen_string_literal: true

require 'rails_helper'

RSpec.describe  Operations::People::Addresses::AddressWorker, :dbclean => :after_each do
  let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:params) do
    person.addresses.first.delete
    {:person_hbx_id => person.hbx_id, :address_id => person.home_address.id}
  end

  it "should respond to #call" do
    result = described_class.new.call(params)
    expect(result).to be_success
  end

  context "for valid params" do
    it "should return success with success message" do
      person.home_address.update_attributes(state: "TE")
      result = described_class.new.call(params)
      expect(result).to be_success
      expect(result.success).to eq("AddressWorker: Completed")
    end
  end

  context "for invalid params" do
    it "should return success with failure message" do
      result = described_class.new.call({:person_hbx_id => person.hbx_id, :address_id => "123"})
      expect(result).to be_success
      expect(result.success).to eq("AddressWorker: Failed")
    end
  end
end