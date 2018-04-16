module BenefitSponsors
  module Organizations
    class EmployerProfileBuilder
      # This employer has already been claimed and has an active staff role
      class EmployerAlreadyClaimedError < StandardError; end
      # The matching organization is ineligible for some other reason, such as
      # being an issuer
      class EmployerIneligibleError < StandardError; end

      def find_or_build_employer_organization(
        legal_name:,
        dba:,
        fein:)
        existing_org = find_existing_organization(fein)
        return existing_org if existing_org
        ::BenefitSponsors::Organizations::Organization.new(
          legal_name: legal_name,
          dba: dba,
          fein: fein
        )
      end

      def build_employer_profile(organization:, entity_kind:)
      end

      def build_office_location(address_1:, address_2:,city:, state:, county:,zip:)
      end

      protected
      def find_existing_organization(fein)
        organization = Organization.by_fein(fein)
        if organization
          has_issuer_profile = organization.profiles.any? do |prof|
            prof.kind_of?(::BenefitSponsors::Organizations::IssuerProfile)
          end
          if has_issuer_profile
            raise EmployerIneligibleError.new
          end
        end
        organization
      end
    end
  end
end
