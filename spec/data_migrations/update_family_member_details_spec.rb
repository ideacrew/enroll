require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_family_member_details")

describe UpdateFamilyMemberDetails, dbclean: :after_each do

  let(:given_task_name) { "update_family_member_details" }
  let(:person1) { FactoryGirl.create(:person) }
  let(:person2) { FactoryGirl.create(:person) }
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member_and_dependent, person: person1)}
  subject { UpdateFamilyMemberDetails.new(given_task_name, double(:current_scope => nil)) }

  before do
    allow(ENV).to receive(:[]).with('hbx_id_1').and_return person1.hbx_id
    allow(ENV).to receive(:[]).with('hbx_id_2').and_return person2.hbx_id
    allow(ENV).to receive(:[]).with("id").and_return(family.family_members.where(is_primary_applicant: false).first.id)
  end

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "Should update family member info", dbclean: :after_each do
    it "update family member info" do
      subject.migrate
      expect(family.reload.family_members.find(ENV['id']).person.id).to eq (person2.id)
      expect(person1.reload.person_relationships.first.relative_id).to eq (person2.id)
    end
  end
end