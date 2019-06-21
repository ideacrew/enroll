require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_carrier_name")

describe UpdateCarrierName, dbclean: :after_each do

  let(:given_task_name) { "update_carrier_name" }
  subject { UpdateCarrierName.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update carrier legal name" do
    let(:organization)  { FactoryBot.create(:organization)}
    let(:new_legal_name) { "New Legal Name" }

    it "allow dependent ssn's to be updated to nil" do
      organization
      ClimateControl.modify fein: organization.fein, name: new_legal_name do
        subject.migrate
      end
      organization.reload
      expect(organization.legal_name).to match(new_legal_name)
    end
  end
end
