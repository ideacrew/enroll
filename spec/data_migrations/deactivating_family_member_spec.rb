require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "deactivating_family_member")

describe DeactivatingFamilyMember, dbclean: :after_each do

  let(:given_task_name) { "deactivating_family_member" }
  subject { DeactivatingFamilyMember.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "add family member to coverage household", dbclean: :after_each do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member_and_dependent)}

    before do
      @dependent = family.family_members.where(is_primary_applicant: false).first
      allow(ENV).to receive(:[]).with("family_member_id").and_return(@dependent.id)
    end

    it "should deactivate duplicate family member" do  
      subject.migrate 
      @dependent.reload
      expect(@dependent.is_active).to eq false
    end
  end
end
