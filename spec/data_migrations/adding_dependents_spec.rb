#require "rails_helper"
#require File.join(Rails.root, "app", "data_migrations", "activate_benefit_group_assignment")
#
#describe AddingDependents do
#
#  let(:given_task_name) { "adding_dependents" }
#  subject { AddingDependents.new(given_task_name, double(:current_scope => nil)) }
#
#  describe "given a task name" do
#    it "has the given task name" do
#      	expect(subject.name).to eql given_task_name
#    end
#  end
#
#  describe "adding dependents" do
#    let(:family)  {FactoryGirl.create(:family, :with_primary_family_member)}
#    before do
#      allow(ENV).to receive(:[]).with('family_id').and_return family.id
#      allow(ENV).to receive(:[]).with('file_name').and_return "dependents.csv"
#    end
#    it "should add new dependent" do
#      	expect(family.dependents.size).to eq 0
#        subject.migrate
#        family.reload
#        expect(family.dependents.size).to eq 3
#    end
#  end
#end
