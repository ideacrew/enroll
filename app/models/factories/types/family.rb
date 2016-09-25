module Factories
  module Types
    class FamilyError < StandardError; end

    class Family < Factories::Types::Base

      def find_or_build(family)
      end

    private
      def match(family)
      end

      def build(person, dependents)
        #only build family if there is no primary family, otherwise return primary family
        if person.primary_family.nil?
          family, primary_applicant = self.initialize_family(person, dependents)
          family.family_members.map(&:__association_reload_on_person)
          saved = save_all_or_delete_new(family, primary_applicant)
        else
          family = person.primary_family
        end
        return family
      end

    end
  end
end
