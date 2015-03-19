class Email
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person
  embedded_in :office_location
  embedded_in :employer_census_member, class_name: "EmployerCensus::Member"

  KINDS = %W(home work)

  field :kind, type: String
  field :address, type: String

  validates_format_of :address, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/
  validates_presence_of  :kind, message: "Choose a type"
  validates_inclusion_of :kind, in: KINDS, message: "%{value} is not a valid email type"

  validates :address,
#    uniqueness: true,
    presence: true


  def match(another_email)
    return false if another_email.nil?
    attrs_to_match = [:kind, :address]
    attrs_to_match.all? { |attr| attribute_matches?(attr, another_email) }
  end

  def attribute_matches?(attribute, other)
    self[attribute] == other[attribute]
  end

end
