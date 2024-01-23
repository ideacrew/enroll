# frozen_string_literal: true

require 'rails_helper'

describe "translations for: en.user_mailer" do
  describe "the user_mailer.broker_linked_notification_email.full_text translation" do
    let(:key) { "user_mailer.broker_linked_notification_email.full_text" }

    it "exists" do
      expect(I18n.exists?(key)).to be_truthy
    end
  end

  describe "the user_mailer.broker_linked_notification_email.subject translation" do
    let(:key) { "user_mailer.broker_linked_notification_email.subject" }

    it "exists" do
      expect(I18n.exists?(key)).to be_truthy
    end
  end

  describe "the user_mailer.broker_staff_linked_notification_email.full_text translation" do
    let(:key) { "user_mailer.broker_staff_linked_notification_email.full_text" }

    it "exists" do
      expect(I18n.exists?(key)).to be_truthy
    end
  end

  describe "the user_mailer.broker_staff_linked_notification_email.subject translation" do
    let(:key) { "user_mailer.broker_staff_linked_notification_email.subject" }

    it "exists" do
      expect(I18n.exists?(key)).to be_truthy
    end
  end
end