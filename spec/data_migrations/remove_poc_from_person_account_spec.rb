require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_poc_from_person_account")

describe RemovePocFromPersonAccount do
  let(:given_task_name) { "remove_poc_from_person_account" }
  subject { RemovePocFromPersonAccount.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "remove the poc from person account" do
    let(:person) { FactoryGirl.create(:person, :with_employer_staff_role)}
    before(:each) do
      allow(ENV).to receive(:[]).with("person_hbx_id").and_return(person.hbx_id)
    end

    it "should delete poc of the person" do
      expect(person.employer_staff_roles.size).not_to eq 0
      subject.migrate
      person.reload
      expect(person.employer_staff_roles.size).to eq 0
    end
  end
end