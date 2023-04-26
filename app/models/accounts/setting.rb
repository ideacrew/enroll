module Accounts
  class Setting
    include Mongoid::Document
    include Mongoid::Timestamps

    CommunicationKinds = %w[electronic_preferred paper_only].freeze
    ElectronicCommunicationKinds = %w[sms smtp].freeze
    LocaleKinds = %w[en].freeze

    embedded_in :profile, class_name: "Accounts::Profile"

    field :locale, type: String
    field :communication_preference, type: String
    field :electronic_communication_method, type: String
  end
end
