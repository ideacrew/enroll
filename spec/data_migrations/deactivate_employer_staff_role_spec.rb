require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "deactivate_employer_staff_role")

describe DeactivateEmployerStaffRole do
  let(:given_task_name) { "deactivate_employer_staff_role" }
  subject { DeactivateEmployerStaffRole.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

 

end