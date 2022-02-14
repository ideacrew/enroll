# frozen_string_literal: true

# rubocop:disable all

module Config::ContactCenterModelConcern
  extend ActiveSupport::Concern

  included do
    delegate :contact_center_name, :to => :class
    delegate :contact_center_phone_number, :to => :class
    delegate :contact_center_short_number, :to => :class
    delegate :contact_center_tty_number, :to => :class
  end

  class_methods do
    def contact_center_name
      @@contact_center_name ||= EnrollRegistry[:enroll_app].setting(:contact_center_name).item
    end

    def contact_center_phone_number
      @contact_center_phone_number ||= Settings.contact_center.phone_number
    end

    def contact_center_short_number
      @contact_center_short_number ||= EnrollRegistry[:enroll_app].setting(:contact_center_short_number).item
    end

    def contact_center_tty_number
      @contact_center_tty_number ||= EnrollRegistry[:enroll_app].setting(:contact_center_tty_number).item
    end
  end
end

# rubocop:enable all
