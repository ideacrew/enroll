require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_hbx_id")

describe RemoveHbxId do
  let(:given_task_name) { "remove_hbx_id" }
  subject { RemoveHbxId.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing person ssn" do
    let(:person) { FactoryBot.create(:person)}

    it "should set person hbx id to nil" do
      ClimateControl.modify person_hbx_id: person.hbx_id do 
        subject.migrate
        person.reload
        expect(person.hbx_id).to eq nil
      end
    end
  end
end
