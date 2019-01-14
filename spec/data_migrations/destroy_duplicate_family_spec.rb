require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "destroy_duplicate_family")

describe DestroyDuplicateFamily, dbclean: :after_each do
  let(:given_task_name) { "change_fein" }
  subject { DestroyDuplicateFamily.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "should destroy invalid family" do
    let(:person) {FactoryBot.create(:person)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member,person:person)}

    let(:active_household) {family.active_household}
    let(:enrollment) { FactoryBot.create(:hbx_enrollment, effective_on:TimeKeeper.date_of_record,aasm_state:'coverage_selected')}


    before(:each) do
      allow(ENV).to receive(:[]).with("family_id").and_return(family.id)
    end

    it "should destroy family when account has no active enrollments" do
      expect(Family.all.count).to eq 1
      subject.migrate
      expect(Family.all.count).to eq 0
    end
  end
end
