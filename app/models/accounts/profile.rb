# frozen_string_literal: true

module Accounts
  # model to store application specific profiles for the account
  class Profile
    include Mongoid::Document
    include Mongoid::Timestamps

    CLIENT_KINDS = %w[enroll edi_db sugar_crm polypress].freeze

    embedded_in :account

    field :client_key, type: String
    embeds_many :settings, class_name: "Accounts::Setting", cascade_callbacks: true, validate: true
  end
end
