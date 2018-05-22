require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "creating_person_record")

describe CreatingPersonRecord, dbclean: :after_each do
  let(:given_task_name) { "creating_person_record" }
  subject { CreatingPersonRecord.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "should create broker_agency_accounts for employer" do
    it "should have broker_agency_account for employer" do
      expect(Person.all.to_a.size).to eq 0 # before migration
      subject.migrate
      expect(Person.all.to_a.size).to eq 1 # after migration
    end
  end
end
