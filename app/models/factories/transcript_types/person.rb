module Factories
  module TranscriptTypes
    class PersonError < StandardError; end

    class Person < Factories::TranscriptTypes::Base

      def initialize
        @fields_to_ignore = ['_id', 'created_at', 'updated_at']

        super
      end

      def find_or_build(person)
        @transcript[:other] = person
        people = match(person)

        case people.count
        when 0
          @transcript[:source_is_new] = true
          @transcript[:source] = initialize_person
        when 1
          @transcript[:source_is_new] = false
          @transcript[:source] = people.first
        else
          message = "Ambiguous person match: more than one person matches criteria"
          raise Factories::TranscriptTypes::PersonError message
        end

        compare
        validate
      end

      private

      def match(person)
        if person.hbx_id.present?
          matched_people = Person.where(hbx_id: person.hbx_id) || []
        else
          matched_people = Person.match_by_id_info(
              ssn: person.ssn,
              dob: person.dob,
              last_name: person.last_name,
              first_name: person.first_name
            )
        end
        matched_people
      end

      def initialize_person
        fields = Person.new.fields.inject({}){|data, (key, val)| data[key] = val.default_val; data }
        fields.delete_if{|key,val| @fields_to_ignore.include?(key)}
        Person.new(fields)
      end
    end
  end
end
