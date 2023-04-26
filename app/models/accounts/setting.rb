# frozen_string_literal: true

module Accounts
  # model to store profile settings
  class Setting
    include Mongoid::Document
    include Mongoid::Timestamps

    COMMUNICATION_KINDS = %w[electronic_preferred paper_only].freeze
    ELECTRONIC_COMMUNICATION_KINDS = %w[sms smtp].freeze
    LOCALE_KINDS = %w[en].freeze

    embedded_in :profile, class_name: "Accounts::Profile"

    field :locale, type: String
    field :communication_preference, type: String
    field :electronic_communication_method, type: String
  end
end
