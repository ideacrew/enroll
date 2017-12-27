require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_person_relationship_kind")

describe UpdatePersonRelationshipKind, dbclean: :after_each do

  let(:given_task_name) { "update_person_relationship_kind" }
  subject { UpdatePersonRelationshipKind.new(given_task_name, double(:current_scope => nil)) }


  # context "given a task name" do
  #   it "has the given task name" do
  #     expect(subject.name).to eql given_task_name
  #   end
  # end

  describe "changing plan year's state" do
    let(:person) { FactoryGirl.create(:person)}
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
    before(:each) do
      person.person_relationships << PersonRelationship.new(relative: person, kind: "child")
      person.save
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.hbx_id)
    end

    it "should change person relationships kind" do
      expect(person.person_relationships.first.kind).to  eq("child")
      subject.migrate
      person.reload
      expect(person.person_relationships.first.kind).to  eq("self")
    end
  end
end
