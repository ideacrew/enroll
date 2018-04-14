module BenefitSponsors
  module Organizations
    class EmployerProfileRegistrationFormMapping
      def available_entity_kinds
        Organizations::Organization::ENTITY_KINDS.map { |a| [a, a] }
      end

      # Just a slug, pull from the right place
      def available_states
        [["District of Columbia", "DC"]]
      end
    end
  end
end
