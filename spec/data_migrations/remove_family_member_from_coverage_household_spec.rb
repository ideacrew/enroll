require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_family_member_from_coverage_household")

describe AddFamilyMemberFromCoverageHousehold, dbclean: :after_each do

  let(:given_task_name) { "remove_family_member_from_coverage_household" }
  subject { RemoveFamilyMemberFromCoverageHousehold.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "remove family member to coverage household", dbclean: :after_each do

    let(:person) { FactoryGirl.create(:person) }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}

    before do
      allow(ENV).to receive(:[]).with('person_hbx_id').and_return person.hbx_id
      allow(ENV).to receive(:[]).with('family_member_hbx_id').and_return person.hbx_id
    end

    it "should remove a family member to household" do

  
    end

  end
end
