require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_duplicate_person")
describe RemoveDuplicatePerson, dbclean: :after_each do

  describe "given a task name" do
    let(:given_task_name) { "remove_duplicate_person" }
    subject {RemoveDuplicatePerson.new(given_task_name, double(:current_scope => nil)) }
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "Remove duplicate person with first_name,last_name & dob and no ssn" do
    subject {RemoveDuplicatePerson.new("remove_duplicate_person", double(:current_scope => nil)) }
    let(:primary_dob){ TimeKeeper.date_of_record.next_month - 57.years }
    let(:person1) { FactoryGirl.create(:person, :with_consumer_role, dob: primary_dob) }
    let(:person2) { FactoryGirl.create(:person, :with_consumer_role, dob: primary_dob) }
    before(:each) do
      allow(ENV).to receive(:[]).with("ssn").and_return(person1.ssn)
      allow(ENV).to receive(:[]).with("first_name").and_return(person1.first_name)
      allow(ENV).to receive(:[]).with("last_name").and_return(person1.last_name)
      allow(ENV).to receive(:[]).with("dob").and_return(person1.dob)
      person2.update_attributes({ :encrypted_ssn => nil, :last_name => person1.last_name, :first_name => person1.first_name})
    end

    it "should set person hbx id to nil" do
      subject.migrate
      expect(Person.active.count).to eq 1
    end
  end
end