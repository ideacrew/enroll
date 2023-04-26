# frozen_string_literal: true

# model to persist Account
class Account
  include Mongoid::Document
  include Mongoid::Timestamps

  field :id, type: String
  field :username, type: String
  field :email, type: String
  field :email_verified, type: Boolean
  field :enabled, type: Boolean
  field :totp, type: Boolean
  field :first_name, type: String
  field :last_name, type: String
  field :password, type: String
  # field :attributes, type: Hash # Not allowed
  field :realm_roles, type: Array
  field :client_roles, type: Array
  field :groups, type: Array
  field :access, type: Hash
  field :not_before, type: Integer

  embeds_many :profiles, class_name: "Accounts::Profile", cascade_callbacks: true, validate: true

end
