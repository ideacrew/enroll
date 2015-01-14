class Email
  include Mongoid::Document
  include Mongoid::Timestamps

  KINDS = %W(home work)

  field :kind, type: String
  field :address, type: String

  validates_format_of :address, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/
  validates_presence_of  :kind, message: "Choose a type"
  validates_inclusion_of :kind, in: KINDS, message: "%{value} is not a valid email type"

  validates :email,
    uniqueness: true,
    presence: true

  embedded_in :person
end
