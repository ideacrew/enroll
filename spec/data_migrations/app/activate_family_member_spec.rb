require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "activate_family_member")

describe ActivateFamilyMember, dbclean: :after_each do

  let(:given_task_name) { "activate_family_member" }
  subject { ActivateFamilyMember.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "activate family member", dbclean: :after_each do

    let!(:person) { FactoryGirl.create(:person, :with_family) }
    let!(:dependent) { FactoryGirl.create(:person) }
    let!(:family_member) { FactoryGirl.create(:family_member, family: person.primary_family ,person: dependent,is_active:false)}
    let!(:coverage_household_member) { coverage_household.coverage_household_members.new(:family_member_id => family_member.id) }
    let(:primary_family){person.primary_family}
    let(:coverage_household){person.primary_family.active_household.immediate_family_coverage_household}

    it "should activate an inactive family member " do
      expect(family_member.is_active?).to eq false 
      allow(ENV).to receive(:[]).with('family_member_id').and_return(family_member.id.to_s)
      subject.migrate
      person.reload
      family_member.reload
      expect(family_member.is_active?).to eq true
    end
  end
end
