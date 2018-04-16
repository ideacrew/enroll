module BenefitSponsors
  module Organizations
    class EmployerProfileRegistrationFormMapping
      attr_accessor :employer_profile_builder

      def initialize(ep_builder = ::BenefitSponsors::Organizations::EmployerProfileBuilder.new)
        @employer_profile_builder = ep_builder
      end

      def available_entity_kinds
        Organizations::Organization::ENTITY_KINDS.map { |a| [a, a] }
      end

      def save(form)
      end

      # Just a slug, actual values should be pulled from the DB
      def available_states
        [["District of Columbia", "DC"]]
      end
    end
  end
end
