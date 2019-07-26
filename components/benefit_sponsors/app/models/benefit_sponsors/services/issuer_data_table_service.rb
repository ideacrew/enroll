# frozen_string_literal: true

module BenefitSponsors
  module Services
    class IssuerDataTableService
      def retrieve_table_data
        ::BenefitSponsors::Organizations::ExemptOrganization.issuer_profiles.sort_by(&:legal_name)
      end
    end
  end
end