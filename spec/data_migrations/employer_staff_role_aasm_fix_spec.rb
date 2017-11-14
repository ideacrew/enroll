require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "employer_staff_role_aasm_fix")

describe EmployerStaffRoleAasmFix do

  let(:given_task_name) { "emploer_staff_role_aasm_fix" }
  subject { EmployerStaffRoleAasmFix.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "employer staff role aasm fix", dbclean: :after_each do
    let(:employer_staff_role) { FactoryGirl.create(:employer_staff_role) }

    context "does not have aasm_state" do
      context "is_active = true" do
        before(:each) do
          employer_staff_role.unset(:aasm_state)
          employer_staff_role.update_attributes!({:is_active => true})
          subject.migrate
          employer_staff_role.reload
        end

        it "should have the aasm_state as is_active" do
          expect(employer_staff_role.aasm_state).to eq "is_active"
        end
      end

      context "is_active = false" do
        before(:each) do
          employer_staff_role.unset(:aasm_state)
          employer_staff_role.update_attributes!({:is_active => false})
          subject.migrate
          employer_staff_role.reload
        end

        it "should have the aasm_state as is_closed" do
          expect(employer_staff_role.aasm_state).to eq "is_closed"
        end
      end
    end
  end
end
