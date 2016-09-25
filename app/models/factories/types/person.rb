module Factories
  module Types
    class PersonError < StandardError; end

    class Person

      def find_or_build(person)
        @transcript[:other] = person

        people = match(person)

        case people.count 
        when 0
          @transcript[:source_is_new] = true
          @transcript[:source] = build(person)
          return @transcript
        when 1
          @transcript[:source_is_new] = false
          @transcript[:source] = people.first
          return @transcript
        else
          message = "Ambiguous person match: more than one person matches criteria"
          raise Factories::Types::PersonError message
        end
      end

    private
      def compare
        
      end

      def match(person)
        if person[:hbx_id].present?
          matched_people = Person.where(hbx_id: person[:hbx_id]) || []
        else
          matched_people = Person.match_by_id_info(
              ssn: person[:ssn],
              dob: person[:dob],
              last_name: person[:last_name],
              first_name: person[:first_name]
            )
        end
        matched_people
      end

      def build(unmatched_person)
        new_person = Person.new
        properties = unmatched_person.attributes.except(:_id, :version, :created_at, :updated_at)
        copy_properties(unmatched_person, new_person, properties)
      end

        if user.present?
          user.roles << context.role_type unless user.roles.include?(context.role_type)
          user.save
          unless person.emails.count > 0
            if user.email.present?
              person.emails.build(kind: "home", address: user.email)
              person.save
            end
          end
        end
        context.person = person
        context.is_new = is_new
      end

      def initialize_person(user, name_pfx, first_name, middle_name,
                                 last_name, name_sfx, ssn, dob, gender, role_type, no_ssn=nil)
          person_attrs = {
            user: user,
            name_pfx: name_pfx,
            first_name: first_name,
            middle_name: middle_name,
            last_name: last_name,
            name_sfx: name_sfx,
            ssn: ssn,
            dob: dob,
            gender: gender,
            no_ssn: no_ssn,
            role_type: role_type
          }
          result = build(person_attrs)
          return result.person, result.is_new
      end
    end
  end
end
