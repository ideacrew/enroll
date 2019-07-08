require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "unset_bga_id")

describe UnsetBgaId, dbclean: :after_each do

  let(:given_task_name) { "UnsetBgaId" }
  subject { UnsetBgaId.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "unset bga id" do

    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household)}

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(hbx_enrollment.hbx_id)
    end

    it "should unset benefit group assignment id" do
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.benefit_group_assignment_id).to eq nil
    end
  end
end
