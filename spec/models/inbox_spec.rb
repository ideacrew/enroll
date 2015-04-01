require 'rails_helper'

RSpec.describe Inbox, :type => :model do
  let (:inbox) {Inbox.new}
  let (:message) {FactoryGirl.build(:message)}
  let (:message_list) {FactoryGirl.build_list(:message, 15)}

  describe "#post_message" do

    context "with valid message" do
      let(:inbox_with_message) { inbox.post_message(message) }

      it "should add to collection" do
        expect(inbox_with_message.messages.size).to eq 1
      end

      pending "add this spec"
      it "message should be findable" do
      end
    end

  end

  describe "#delete_message" do
    let(:orphan_message) {FactoryGirl.build(:message)}
    let(:message_count) {15}

    let(:inbox_with_many_messages) do
      inbox = Inbox.new
      message_count.times do
        message = FactoryGirl.build(:message)
        inbox.post_message(message)
      end
      inbox
    end

    context "messages are loaded" do
      it "inbox should contain list of messages" do
        expect(inbox_with_many_messages.messages.size).to eq message_count
      end
    end

    context "and message to delete is not in mailbox" do
      it "should not change message count" do
        expect(inbox_with_many_messages.delete_message(orphan_message).messages.size).to eq message_count
      end
    end

    context "and message to delete is in mailbox" do
      let(:deleteable_message) { inbox_with_many_messages.messages.first }
      it "should reduce message count by 1" do
        expect(inbox_with_many_messages.delete_message(deleteable_message).messages.size).to eq message_count - 1
      end
    end

  end


end
