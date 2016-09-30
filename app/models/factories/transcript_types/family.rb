module Factories
  module TranscriptTypes
    class FamilyError < StandardError; end

    class Family < Factories::TranscriptTypes::Base

      def self.associations
        [
          "person", 
          "family_members", 
          "irs_groups",
          "broker_agency_accounts", 
          "general_agency_accounts"
        ]
      end

      def initialize
        super
      end

      def find_or_build(family)
        @transcript[:other] = family

        families = match_instance(family)

        case families.count
        when 0
          @transcript[:source_is_new] = true
          @transcript[:source] = initialize_enrollment
        when 1
          @transcript[:source_is_new] = false
          @transcript[:source] = families.first
        else
          message = "Ambiguous family match: more than one family matches criteria"
          raise Factories::TranscriptTypes::FamilyError message
        end

        compare_instance
        validate_instance
      end

    private

      def match_instance(family)
        Family.where(e_case_id: family.e_case_id)
      end

      def initialize_enrollment
      end

      # def match(family)
      # end

      # def build(person, dependents)
      #   #only build family if there is no primary family, otherwise return primary family
      #   if person.primary_family.nil?
      #     family, primary_applicant = self.initialize_family(person, dependents)
      #     family.family_members.map(&:__association_reload_on_person)
      #     saved = save_all_or_delete_new(family, primary_applicant)
      #   else
      #     family = person.primary_family
      #   end
      #   return family
      # end

    end
  end
end
