module Parsers::Xml::Cv::Importers
  class IndividualParser
    include HappyMapper
    include ::Openhbx::Cv2::Namespace

    register_namespace "cv", NS_URI
    tag 'individual'
    namespace 'cv'

    element :id, String, tag: "id/cv:id"
    has_one :person, ::Openhbx::Cv2::Person, tag: "person"
    has_one :person_demographics, ::Openhbx::Cv2::PersonDemographics, tag: "person_demographics"

    #element :individual, Openhbx::Cv2::Individual

    def get_person_object
      nil if person.nil? || person_demographics

      gender = person_demographics.sex.match(/gender#(.*)/)[1] rescue ''
      hbx_id = person.id.match(/hbx_id#(.*)/)[1] rescue ''

      person_object = Person.new(
        hbx_id: hbx_id,
        first_name: person.first_name,
        middle_name: person.middle_name,
        last_name: person.last_name,
        name_pfx: person.name_prefix,
        name_sfx: person.name_suffix,
        ssn: person_demographics.ssn,
        dob: person_demographics.birth_date.to_date,
        gender: gender,
        ethnicity: [person_demographics.ethnicity],
        language_code: person_demographics.language_code,
        race: person_demographics.race,
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
