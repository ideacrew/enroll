require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_erroneous_personrelationship_records")

describe RemoveErroneousPersonrelationshipRecords, dbclean: :after_each do

  let(:given_task_name) { "remove_incorrect_person_relationship" }
  subject { RemoveErroneousPersonrelationshipRecords.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "remove erroneous records" do
    let!(:person) { FactoryGirl.create(:person, :with_family) }
    let(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person)}
    let(:family_member) {FactoryGirl.create(:family_member, family: family, is_active: true)}

    before(:each) do
      allow(ENV).to receive(:[]).with('hbx_id').and_return person.hbx_id
    end

    it "should destroy the person relationship" do
      subject.migrate
      person.reload
      expect(person.person_relationships.size).to eq 0
    end
  end
end