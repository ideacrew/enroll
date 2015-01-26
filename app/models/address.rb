class Address
  include Mongoid::Document
  include Mongoid::Timestamps

  # include MergingModel

  KINDS = %W(home work mailing)

  field :kind, type: String
  field :address_1, type: String
  field :address_2, type: String, default: ""
  field :address_3, type: String, default: ""
  field :city, type: String
  field :county, type: String
  field :state, type: String
  field :location_state_code, type: String
  field :zip, type: String
  field :zip_extension, type: String
  field :country_name, type: String, default: ""
  field :full_text, type: String

  validates_presence_of :kind, :address_1, :city, :state, :zip

  validates_inclusion_of :kind, in: KINDS, message: "'%{value}'' is not a valid address type"

  validates :zip,
    format:
      {
        :with => /\A\d{5}(-\d{4})?\z/,
        :message => "should be in the form: 12345 or 12345-1234"
      }

  embedded_in :person
  embedded_in :employer, :inverse_of => :addresses
  embedded_in :employer_office
  embedded_in :broker

  before_save :clean_fields

  def location
    nil #todo
  end

  def clean_fields
    attrs_to_clean = [:kind, :address_1, :address_2, :city, :state, :zip]
    attrs_to_clean.each do |a|
      self[a].strip! unless self[a].blank?
    end
  end

  def formatted_address
    city.present? ? city_delim = city + "," : city_delim = city
    line3 = [city_delim, state, zip].reject(&:nil? || empty?).join(' ')
    [address_1, address_2, line3].reject(&:nil? || empty?).join('<br/>').html_safe
  end

  def full_address
    city.present? ? city_delim = city + "," : city_delim = city
    [address_1, address_2, city_delim, state, zip].reject(&:nil? || empty?).join(' ')
  end

  def home?
    "home" == self.kind.downcase
  end

  def match(another_address)
    return(false) if another_address.nil?
    attrs_to_match = [:kind, :address_1, :address_2, :city, :state, :zip]
    attrs_to_match.all? { |attr| attribute_matches?(attr, another_address) }
  end

  def attribute_matches?(attribute, other)
    return true if (self[attribute] == nil && other[attribute] == "")
    safe_downcase(self[attribute]) == safe_downcase(other[attribute])
  end

  def self.make(data)
    address = Address.new
    address.kind = data[:type]
    address.address_1 = data[:street1]
    address.address_2 = data[:street2]
    address.city = data[:city]
    address.state = data[:state]
    address.zip = data[:zip]
    address
  end

  private

  def safe_downcase(val)
    val.nil? ? nil : val.downcase
  end
end
