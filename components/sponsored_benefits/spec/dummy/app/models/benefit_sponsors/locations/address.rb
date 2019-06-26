module BenefitSponsors
  module Locations
    class Address
      include Mongoid::Document
      include Mongoid::Timestamps

      KINDS = %W(home work mailing)
      OFFICE_KINDS = %W(primary mailing branch)

      # The type of address
      field :kind, type: String

      field :address_1, type: String, default: ""
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

      validates :zip, presence: true # , unless: :plan_design_model?
      validates :kind, presence: true # , unless: :plan_design_model?

      validates :kind,
        inclusion: { in: KINDS + OFFICE_KINDS, message: "%{value} is not a valid address kind" },
        allow_blank:true

      validates :address_1, presence: {message: "Please enter address_1"}
      validates :city, presence: {message: "Please enter city"}

      validates :zip,
        allow_blank: false,
        format: {
            :with => /\A\d{5}(-\d{4})?\z/,
            :message => "should be in the form: 12345 or 12345-1234"
          }
      embedded_in :office_location

      def location
        nil #todo
      end

      def office_is_primary_location?
        kind == 'primary'
      end

      def blank?
        [:city, :zip, :address_1, :address_2].all? do |attr|
          self.send(attr).blank?
        end
      end

      def to_html
        if address_2.blank?
          "<div>#{address_1.strip()}</div><div>#{city}, #{state} #{zip}</div>".html_safe
        else
          "<div>#{address_1.strip()}</div><div>#{address_2}</div><div>#{city}, #{state} #{zip}</div>".html_safe
        end
      end

      def to_s
        city.present? ? city_delim = city + "," : city_delim = city
        line3 = [city_delim, state, zip].reject(&:nil? || empty?).join(' ')
        [address_1, address_2, line3].reject(&:nil? || empty?).join('<br/>').html_safe
      end

      def to_a
        [kind, address_1, address_2.to_s, city, state, zip]
      end
    
      def full_address
        city.present? ? city_delim = city + "," : city_delim = city
        [address_1, address_2, city_delim, state, zip].reject(&:nil? || empty?).join(' ')
      end

      def address_1=(new_address_1)
        write_attribute(:address_1, new_address_1.to_s.squish)
      end

      def address_2=(new_address_2)
        write_attribute(:address_2, new_address_2.to_s.squish)
      end

      def address_3=(new_address_3)
        write_attribute(:address_3, new_address_3.to_s.squish)
      end

      def city=(new_city)
        write_attribute(:city, new_city.to_s.squish)
      end

      def state=(new_state)
        write_attribute(:state, new_state.to_s.squish)
      end

      def zip=(new_zip)
        write_attribute(:zip, new_zip.to_s.squish)
      end

      def zip_without_extension
        return nil if zip.blank?
        if zip =~ /-/
          zip.split("-").first
        else
          zip
        end
      end

      def zip_extension
        return nil if zip.blank?
        if zip =~ /-/
          zip.split("-").last
        else
          nil
        end
      end

      def mailing?
        kind.to_s == "mailing"
      end

      def home?
        "home" == self.kind.to_s
      end

      def matches?(another_address)
        return(false) if another_address.nil?
        attrs_to_match = [:kind, :address_1, :address_2, :address_3, :city, :state, :zip]
        attrs_to_match.all? { |attr| attribute_matches?(attr, another_address) }
      end

      def same_address?(another_address)
        return(false) if another_address.nil?
        attrs_to_match = [:address_1, :address_2, :address_3, :city, :state, :zip]
        attrs_to_match.all? { |attr| attribute_matches?(attr, another_address) }
      end

      def office_kinds
        OFFICE_KINDS
      end

      private

      def attribute_matches?(attribute, other)
        self[attribute].to_s.downcase == other[attribute].to_s.downcase
      end
    end
  end
end
