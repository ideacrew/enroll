class Phone
  include Mongoid::Document
  include Mongoid::Timestamps

  KINDS = %W(home work mobile)

  field :kind, type: String
  field :phone_number, type: String
  field :extension, type: String, default: ""
  field :primary, type: Boolean
  field :country_code, type: String, default: ""
  field :area_code, type: String, default: ""
  field :full_phone_number, type: String, default: ""

  validates_presence_of  :phone_number
  validates_presence_of  :kind, message: "Choose a type"
  validates_inclusion_of :kind, in: KINDS, message: "%{value} is not a valid phone type"

  embedded_in :person, :inverse_of => :phones
  embedded_in :employer, :inverse_of => :phones
  embedded_in :broker, :inverse_of => :phones

  def match(another_phone)
    return(false) if another_phone.nil?
    attrs_to_match = [:kind, :phone_number]
    attrs_to_match.all? { |attr| attribute_matches?(attr, another_phone) }
  end

  def attribute_matches?(attribute, other)
    self[attribute] == other[attribute]
  end

  def phone_number=(value)
    super filter_non_numbers(value)
  end

  def extension=(value)
    super filter_non_numbers(value)
  end

  def self.make(data)
    phone = Phone.new
    phone.kind = data[:kind]
    phone.phone_number = data[:phone_number]
    phone
  end

private
  def filter_non_numbers(str)
    str.gsub(/\D/,'') if str.present?
  end
end
