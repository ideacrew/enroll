# frozen_string_literal: true

# Embedded model that stores a location address
class Address
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::History::Trackable

  embedded_in :person
  embedded_in :office_location
  embedded_in :census_member, class_name: "CensusMember"

  KINDS = %w[home work mailing].freeze
  OFFICE_KINDS = %w[primary mailing branch].freeze

  # Quadrants
  QUADRANTS = %w[N NORTH S SOUTH E EAST W WEST NE NORTHEAST NW NORTHWEST SE SOUTHEAST SW SOUTHWEST].freeze

  # Quadrants
  QUADRANTS = %w[N NORTH S SOUTH E EAST W WEST NE NORTHEAST NW NORTHWEST SE SOUTHEAST SW SOUTHWEST].freeze

  # The type of address
  field :kind, type: String

  field :address_1, type: String
  field :address_2, type: String, default: ""
  field :address_3, type: String, default: ""

  # The name of the city where this address is located
  field :city, type: String

  # The name of the county where this address is located
  field :county, type: String, default: ''

  # The name of the U.S. state where this address is located
  field :state, type: String

  # @todo Add support for FIPS codes
  field :location_state_code, type: String

  # @deprecated Use {#to_s} or {#to_html} instead
  field :full_text, type: String

  # The postal zip code where this address is located
  field :zip, type: String

  # The name of the country where this address is located
  field :country_name, type: String, default: ""

  # The name of the quadrant where this address is located
  field :quadrant, type: String, default: ""

  # The name of the quadrant where this address is located
  field :quadrant, type: String, default: ""

  track_history :on => [:fields],
                :scope => :person,
                :modifier_field => :modifier,
                :modifier_field_optional => true,
                :version_field => :tracking_version,
                :track_create => true,    # track document creation, default is false
                :track_update => true,    # track document updates, default is true
                :track_destroy => true

  validates_presence_of :address_1, :city, :state, :zip

  validates :kind,
            inclusion: { in: KINDS + OFFICE_KINDS, message: "%{value} is not a valid address kind" },
            allow_blank: false

  validates :zip,
            format: {
              :with => /\A\d{5}(-\d{4})?\z/,
              :message => "should be in the form: 12345 or 12345-1234"
            }

  before_validation :detect_quadrant
  validate :quadrant_check

  def detect_quadrant
    self.quadrant = QUADRANTS.map { |word| self.address_1&.upcase&.scan(/\b#{word}\b/) }.flatten.first if EnrollRegistry.feature_enabled?(:validate_quadrant)
  end

  def quadrant_check
    return unless EnrollRegistry.feature_enabled?(:validate_quadrant)
    return unless EnrollRegistry[:validate_quadrant].settings(:inclusions).item.include?(self.state)
    return unless EnrollRegistry[:validate_quadrant].settings(:exclusions).item.exclude?(self.zip)
    return unless self.quadrant.blank?
    errors.add(:quadrant, "not present")
  end

  # @note Add support for GIS location
  def location
    nil #todo
  end

  def office_is_primary_location?
    kind == 'primary'
  end

  # Determine if an address instance is empty
  #
  # @example Is the address blank?
  #   model.blank?
  #
  # @return [ true, false ] true if blank, false if present
  def blank?
    [:city, :zip, :address_1, :address_2].all? do |attr|
      self.send(attr).blank?
    end
  end

  # Get the full address formatted as a string with each line enclosed within html <div> tags
  #
  # @example Get the full address as a <div> delimited string
  #   model.to_html
  #
  # @return [ String ] the full address
  def to_html
    if address_2.blank?
      "<div>#{address_1.strip}</div><div>#{city}, #{state} #{zip}</div>".html_safe
    else
      "<div>#{address_1.strip}</div><div>#{address_2}</div><div>#{city}, #{state} #{zip}</div>".html_safe
    end
  end

  # Get the full address formatted as a <br/> delimited string
  #
  # @example Get the full address formatted as a <br/> delimited string
  #   model.to_s
  #
  # @return [ String ] the full address
  def to_s
    city_delim = city.present? ? "#{city}," : city
    line3 = [city_delim, state, zip].reject(&:nil? || empty?).join(' ')
    [address_1, address_2, line3].reject(&:nil? || empty?).join('<br/>').html_safe
  end

  def to_a
    [kind, address_1, address_2.to_s, city, state, zip]
  end

  # Get the full address formatted as a string
  #
  # @example Get the full address formatted as a string
  #   model.full_address
  #
  # @return [ String ] the full address
  def full_address
    city_delim = city.present? ? "#{city}," : city
    [address_1, address_2, city_delim, state, zip].reject(&:nil? || empty?).join(' ')
  end

  # Sets the address type.
  #
  # @overload kind=(new_kind)
  #
  # @param new_kind [ KINDS ] The address type.
  # @param new_kind [ OFFICE_KINDS ] The {OfficeLocation} address type.
  def kind=(new_kind)
    kind_val = new_kind.to_s.squish.downcase
    if kind_val == 'primary' && office_location.present? && office_location.is_primary
      write_attribute(:kind, 'work')
    else
      write_attribute(:kind, kind_val)
    end
  end

  # Gets the address type.
  #
  # @overload kind
  #
  # @return [ KINDS ] address type
  # @return [ OFFICE_KINDS ] If the address is embedded in {OfficeLocation} address type
  def kind
    kind_val = read_attribute(:kind)
    if office_location.present? && office_location.is_primary && kind_val == 'work'
      'primary'
    else
      kind_val
    end
  end

  # @overload address_1=(new_address_1)
  #
  # Sets the new first line of address
  #
  # @param new_address_1 [ String ] Address line number 1
  def address_1=(new_address_1)
    write_attribute(:address_1, new_address_1.to_s.squish)
  end

  # @overload address_2=(new_address_2)
  #
  # Sets the new second line of address
  #
  # @param new_address_2 [ String ] Address line number 2
  def address_2=(new_address_2)
    write_attribute(:address_2, new_address_2.to_s.squish)
  end

  # @overload address_3=(new_address_3)
  #
  # Sets the new third line of address
  #
  # @param new_address_3 [ String ] Address line number 3
  def address_3=(new_address_3)
    write_attribute(:address_3, new_address_3.to_s.squish)
  end

  # @overload city=(new_city)
  #
  # Sets the new city name
  #
  # @param new_city [String] the new city name
  def city=(new_city)
    write_attribute(:city, new_city.to_s.squish)
  end

  # @overload state=(new_state)
  #
  # Sets the new state name
  #
  # @param new_state [String] the new state name
  def state=(new_state)
    write_attribute(:state, new_state.to_s.squish)
  end

  # @overload zip=(new_zip)
  #
  # Sets the new five or nine digit postal zip code value
  #
  # @example Set five digit postal zip code
  #   model.zip = "20002"
  # @example Set nine digit postal zip code
  #   model.zip = "20002-0001"
  #
  # @param new_zip [String] the new zip code
  def zip=(new_zip)
    write_attribute(:zip, new_zip.to_s.squish)
  end

  # Get the five digit postal zip code for this address, omitting the four digit extension
  #
  # @example Get the five digit postal zip code
  #   model.zip_without_extension
  #
  # @return [ String ] The five digit zip code.
  def zip_without_extension
    return nil if zip.blank?
    if zip =~ /-/
      zip.split("-").first
    else
      zip
    end
  end

  # Get the postal zip code four digit extension for this address
  #
  # @example Get the four digit postal zip code extension
  #   model.zip_extension
  #
  # @return [ String ] The four digit zip code extension.
  def zip_extension
    return nil if zip.blank?
    zip.split("-").last if zip =~ /-/
  end

  # Determine if this address is type: "mailing"
  #
  # @example Is the address a mailing address?
  #   model.mailing?
  #
  # @return [ true, false ] true if mailing type, false if not mailing type
  def mailing?
    kind.to_s == "mailing"
  end

  # Determine if this address is type: "home"
  #
  # @example Is the address a home address?
  #   model.home?
  #
  # @return [ true, false ] true if home type, false if not home type
  def home?
    self.kind.to_s == "home"
  end

  # Compare passed address with this address
  #
  # @param another_address [ Object ] The address to be compared.
  #
  # @return [ true, false ] true if addresses are the same, false if addresses are different
  def matches_addresses?(another_address)
    return(false) if another_address.nil?
    attrs_to_match = [:kind, :address_1, :address_2, :address_3, :city, :state, :zip]
    attrs_to_match.all? { |attr| attribute_matches?(attr, another_address) }
  end

  def same_address?(another_address)
    return(false) if another_address.nil?
    attrs_to_match = [:address_1, :address_2, :address_3, :city, :state, :zip]
    attrs_to_match.all? { |attr| attribute_matches?(attr, another_address) }
  end

  private

  def attribute_matches?(attribute, other)
    self[attribute].to_s.downcase == other[attribute].to_s.downcase
  end
end
