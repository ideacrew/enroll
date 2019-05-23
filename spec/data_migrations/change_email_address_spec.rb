require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_email_address")

describe ChangeEmailAddress, dbclean: :after_each do
  let(:given_task_name) { "change_email_address" }
  subject { ChangeEmailAddress.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "change the email of a person" do
    let(:person) { FactoryBot.create(:person, :with_work_email, hbx_id: "123123123") }

    it "should change the email of the given account" do
      ClimateControl.modify person_hbx_id: person.hbx_id,
                            old_email: person.emails.first.address,
                            new_email: 'NewEmail@gmail.com' do
        email=person.emails.first.address
        expect(person.emails.first.address).to eq email
        subject.migrate
        person.reload
        expect(person.emails.first.address).to eq "NewEmail@gmail.com"
      end
    end
  end

  describe "not change the email if hbx_id not found" do
    let(:person) { FactoryBot.create(:person, :with_work_email) }

    it "should change the email of the given account" do
      ClimateControl.modify person_hbx_id: '',
                            old_email: person.emails.first.address,
                            new_email: 'NewEmail@gmail.com' do
        email=person.emails.first.address
        expect(person.emails.first.address).to eq email
        subject.migrate
        person.reload
        expect(person.emails.first.address).to eq email
      end
    end
  end
end
