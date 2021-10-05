# frozen_string_literal: true

require "rails_helper"

describe "Update Broker Emails", dbclean: :after_all do
  let(:given_task_name) { "update_bulk_broker_emails" }
  subject { UpdateBulkBrokerEmails.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  filename = "update_bulk_broker_emails_*.csv"
  csv_files = Dir.glob(filename)
  if csv_files.present?
    describe "spec for bulk broker email updates" do
      # These values come from test CSV
      let!(:broker_role) { FactoryBot.create(:broker_role, aasm_state: "active", person: person, npn: "1111") }
      let!(:person) { FactoryBot.create(:person, first_name: "Jimmy", last_name: "Stephens") }
      let(:original_broker_email_address) { "fakeemail1@fake.com" }
      let!(:original_email) { person.emails.create(kind: "work", address: original_broker_email_address) }
      let(:new_broker_email_address) {"fakeemail9@fake.com"}
      before do
        Rails.application.load_tasks
        Rake::Task['migrations:update_bulk_broker_emails'].invoke
      end

      it "should update the broker email" do
        person.reload
        expect(person.emails.where(address: new_broker_email_address).present?).to eq(true)
      end
    end
  end
end