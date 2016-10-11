module Parsers::Xml::Cv::Importers
  class EnrollmentParser
    include HappyMapper
    tag 'enrollment'

    element :type, String
    element :market, String
    #element :policy, Parsers::Xml::Cv::Importers::PolicyParser, tag: 'policy'
    element :policy, Openhbx::Cv2::Policy

    def get_person_object
      return nil unless policy

      policy.enrollees.map do |enrollee|
        person = enrollee.member.person rescue nil
        nil if person.nil?
        person_object = Person.new(
          id: person.id.match(/people\/(.*)/)[1],
          hbx_id: enrollee.member.id.match(/hbx_id=(.*)/)[1],
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
            state: address.location_state_code,
            zip: address.postal_code,
            kind: kind,
          )
          person_object.addresses << addr_object
        end
        person_object
      end.compact
    end

    def get_errors_for_person_object
      people = get_person_object
      return nil if people.blank?

      people.map do |person|
        nil if person.valid?
        bubble_address_errors_by_person(person)
        person.errors.full_messages
      end
    end

    def to_hash
      response = {
        type: type,
        market: market,
        policy: policy,
      }

      response
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
