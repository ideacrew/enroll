class Email
  include Mongoid::Document
  include Mongoid::Timestamps

  # include MergingModel

  KINDS = %W(home work)

  field :kind, type: String
  field :email_address, type: String

  validates_presence_of  :email_address
  validates_format_of :email_address, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/
  validates_presence_of  :kind, message: "Choose a type"
  validates_inclusion_of :kind, in: KINDS, message: "%{value} is not a valid email type"

  embedded_in :person

  def match(another_email)
    return false if another_email.nil?
    attrs_to_match = [:email_type, :email_address]
    attrs_to_match.all? { |attr| attribute_matches?(attr, another_email) }
  end

  def attribute_matches?(attribute, other)
    self[attribute] == other[attribute]
  end

  def merge_update(m_email)
    merge_with_overwrite(
      m_email,
      :email_address
    )
  end

  def self.make(data)
    email = Email.new
    email.email_type = data[:email_type]
    email.email_address = data[:email_address]
    email
  end
end
