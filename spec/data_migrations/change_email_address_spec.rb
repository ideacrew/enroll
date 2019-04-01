require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_email_address")

describe ChangeEmailAddress, dbclean: :after_each do
  let(:given_task_name) { "change_email_address" }
  subject { ChangeEmailAddress.new(given_task_name, double(:current_scope => nil)) }
  after :each do
    ["person_hbx_id", "old_email", "new_email"].each do |env_variable|
      ENV[env_variable] = nil
    end
  end
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "change the email of a person" do
    let(:person) { FactoryBot.create(:person, :with_work_email, hbx_id: "123123123") }
    before(:each) do
      ENV["person_hbx_id"] = person.hbx_id
      ENV["old_email"] = person.emails.first.address
      ENV["new_email"] = 'NewEmail@gmail.com'
    end
    it "should change the email of the given account" do
      email=person.emails.first.address
      expect(person.emails.first.address).to eq email
      subject.migrate
      person.reload
      expect(person.emails.first.address).to eq "NewEmail@gmail.com"
    end
  end
  describe "not change the email if hbx_id not found" do
    let(:person) { FactoryBot.create(:person, :with_work_email) }
    before(:each) do
      ENV["person_hbx_id"] = ''
      ENV["old_email"] = person.emails.first.address
      ENV["new_email"] = 'NewEmail@gmail.com'
    end
    it "should change the email of the given account" do
      email=person.emails.first.address
      expect(person.emails.first.address).to eq email
      subject.migrate
      person.reload
      expect(person.emails.first.address).to eq email
    end
  end
end
