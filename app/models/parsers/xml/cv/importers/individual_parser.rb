module Parsers::Xml::Cv::Importers
  class IndividualParser
    include HappyMapper
    tag "individuals"

    element :individual, Openhbx::Cv2::Individual

    def get_person_object
      person = individual.person rescue nil
      nil if person.nil?

      person_object = Person.new(
        id: person.id.match(/people\/(.*)/)[1],
        first_name: person.first_name,
        middle_name: person.middle_name,
        last_name: person.last_name,
        name_pfx: person.name_prefix,
        name_sfx: person.name_suffix,
      )
      person.addresses.each do |address|
        kind = address.type.match(/address_type#(.*)/)[1] rescue 'home'
        addr_object = Address.new(
          address_1: address.address_line_1,
          address_2: address.address_line_2,
          city: address.location_city_name,
          location_state_code: address.location_state_code,
          zip: address.postal_code,
          kind: kind,
        )
        person_object.addresses << addr_object
      end
      person_object
    end

    def get_errors_for_person_object
      person = get_person_object
      return nil if person.blank? || person.valid?
      person.errors.full_messages
    end

    private
    def bubble_address_errors_by_person(person)
      addresses = person.addresses.select {|a| !a.valid?}
      if person.errors.has_key?(:addresses) && addresses.present?
        addresses.each do |address|
          address.errors.each do |k, v|
            person.errors.add("#{address.kind} address: #{k}", v)
          end
        end
        person.errors.delete(:addresses)
      end
    end
  end
end
