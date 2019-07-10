 # frozen_string_literal: true

module BenefitSponsors
  module Services
    class IssuerDataTableService

      attr_accessor :filter

      def initialize(params = {})
        @filter = params[:filter]
      end

      def retrieve_table_data
        ::BenefitSponsors::Organizations::Organization.issuer_profiles
      end

    end
  end
end