class FamilyMemberSnapshot
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps

  embedded_in :initial_application_snapshot

  field :member_snapshot, type: String
  field :person_snapshot, type: String
  field :consumer_role_snapshot, type: String
  field :lawful_presence_determination_snapshot, type: String
  field :addresses_snapshot, type: String
  field :phones_snapshot, type: String
  field :emails_snapshot, type: String


end