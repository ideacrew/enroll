require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_family_member")

describe RemoveFamilyMember do
  let(:given_task_name) {"remove_family_member"}
  subject {RemoveFamilyMember.new(given_task_name, double(:current_scope => nil))}

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "removing duplicate family member" do
    let(:person) {FactoryGirl.create(:person)}
    let(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person)}
    let(:family_member1) {FactoryGirl.create(:family_member, family: family)}
    let(:family_member2) {FactoryGirl.create(:family_member, family: family)}

    before do
      allow(ENV).to receive(:[]).with('person_hbx_id').and_return person.hbx_id
      allow(ENV).to receive(:[]).with('person_first_name').and_return family_member1.person.first_name
      allow(ENV).to receive(:[]).with('person_last_name').and_return family_member1.person.last_name
    end

    it "should remove a family member based on first and last names" do
      size = family.family_members.size
      subject.migrate
      person.reload
      family.reload
      expect(family.family_members.size).to eq size-1
    end
  end


  describe "removing all duplicate family member" do
    let(:person) {FactoryGirl.create(:person)}
    let(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person)}
    let(:family_member1) {FactoryGirl.create(:family_member, family: family)}
    let(:family_member2) {FactoryGirl.create(:family_member, family: family)}

    before do
      allow(ENV).to receive(:[]).with('person_hbx_id').and_return person.hbx_id
      allow(ENV).to receive(:[]).with('person_first_name').and_return "#{family_member1.person.first_name},#{family_member2.person.first_name}"
      allow(ENV).to receive(:[]).with('person_last_name').and_return "#{family_member1.person.last_name},#{family_member2.person.last_name}"
    end

    it "should remove a family member based on first and last names" do
      size = family.family_members.size
      subject.migrate
      person.reload
      family.reload
      expect(family.family_members.size).to eq size-2
    end
  end
end
