module Accounts
  class Profile
    include Mongoid::Document
    include Mongoid::Timestamps

    ClientKinds = %w[enroll edi_db sugar_crm polypress].freeze

    embedded_in :account

    field :client_key, type: String
    embeds_many :settings, class_name: "Accounts::Setting", cascade_callbacks: true, validate: true 
  end
end
