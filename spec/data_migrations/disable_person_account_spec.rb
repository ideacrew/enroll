require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "disable_person_account")

describe DisablePersonAccount do

  let(:given_task_name) { "disable_person_account" }
  subject { DisablePersonAccount.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "disable person account", dbclean: :after_each do
    let(:person) { FactoryBot.create(:person, :with_ssn, is_active: true, is_disabled: nil) }
    let(:employee_role) { FactoryBot.create(:employee_role, person: person)}
    it "should disable the person" do
      ClimateControl.modify hbx_id: person.hbx_id do 
        subject.migrate
        person.reload
        expect(person.is_active).to eq false
        expect(person.is_disabled).to eq true
      end
    end
  end
end
