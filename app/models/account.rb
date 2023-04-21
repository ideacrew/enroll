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
  field :attributes, type: Hash
  field :realm_roles, type: Array
  field :client_roles, type: Array
  field :groups, type: Array
  field :access, type: Hash
  field :profiles, type: Array
  field :not_before, type: Integer

end
