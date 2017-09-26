require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_person_id_for_family_member")

describe ChangePersonIdForFamilyMember, dbclean: :after_each do
  let(:given_task_name) { "change_person_id_for_family_member" }
  subject { ChangePersonIdForFamilyMember.new(given_task_name, double(:current_scope => nil)) }
  
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  
  describe "change person id for family member" do
    let(:person) { FactoryGirl.create(:person) }
    let(:person2) { FactoryGirl.create(:person) }
    let(:person3) { FactoryGirl.create(:person) }
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
    
    before :each do
      allow(person).to receive(:primary_family).and_return(family)
      person.primary_family.relate_new_member(person2, "spouse")
      person.primary_family.save
      allow(ENV).to receive(:[]).with("family_member_id").and_return(person.primary_family.family_members.last.id)
      allow(ENV).to receive(:[]).with("person_hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("dependent_hbx_id").and_return(person3.hbx_id)
    end
    
    it "should update the family members person id" do
      expect(person.primary_family.family_members.last.person_id).to eq person2.id
      subject.migrate
      person.primary_family.reload
      expect(person.primary_family.family_members.last.person_id).to eq person3.id
    end
    
  end
end