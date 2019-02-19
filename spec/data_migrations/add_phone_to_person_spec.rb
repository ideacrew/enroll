require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_phone_to_person")

describe AddPhoneToPerson, dbclean: :after_each do
  let(:given_task_name) { "add_phone_to_person" }
  subject { AddPhoneToPerson.new(given_task_name, double(:current_scope => nil)) }

  describe "Adding a phone to a person" do
    let(:phone) { FactoryGirl.build(:phone, kind: "work", full_phone_number: "3014667333")}
    let(:person) { FactoryGirl.create(:person, ssn: "009998887", phones:[phone]) }

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.hbx_id)
    end

    it "should save the new phone record if given correct kind and full_phone_number" do
      allow(ENV).to receive(:[]).with("kind").and_return('work')
      allow(ENV).to receive(:[]).with("full_phone_number").and_return('3014667333')

      subject.migrate
      person.reload
      expect(person.phones.where(kind:'work').first.full_phone_number).to eq '3014667333'
    end

    it "should not save the phone record if given kind does not exist" do
      allow(ENV).to receive(:[]).with("kind").and_return('fake')
      allow(ENV).to receive(:[]).with("full_phone_number").and_return('3014667333')

      expect{FactoryGirl.create(:phone, full_phone_number: ENV['full_phone_number'], kind: ENV['kind'])}.to raise_error(/Kind fake is not a valid phone type/)
    end

  end
end
