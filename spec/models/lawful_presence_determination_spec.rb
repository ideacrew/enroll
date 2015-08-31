require 'rails_helper'

describe LawfulPresenceDetermination do
  let(:consumer_role) {
    FactoryGirl.create(:consumer_role_object)
  }
  let(:person_id) { consumer_role.person.id }
  let(:payload) { "lsjdfioennnklsjdfe" }

  describe "being given an ssa response which fails" do
    it "should have the ssa response document" do
      consumer_role.lawful_presence_determination.ssa_responses << EventResponse.new({received_at: Time.now, body: payload})
      consumer_role.person.save!
      found_person = Person.find(person_id)
      ssa_response = found_person.consumer_role.lawful_presence_determination.ssa_responses.first
      expect(ssa_response.body).to eq payload
    end
  end

  describe "being given an ssa response which fails" do
    it "should have the ssa response document" do
      consumer_role.lawful_presence_determination.vlp_responses << EventResponse.new({received_at: Time.now, body: payload})
      consumer_role.person.save!
      found_person = Person.find(person_id)
      ssa_response = found_person.consumer_role.lawful_presence_determination.vlp_responses.first
      expect(ssa_response.body).to eq payload
    end
  end
end

