 # frozen_string_literal: true

module BenefitSponsors
  module Services
    class ProductDataTableService
      attr_accessor :issuer_profile_id

      def initialize(params = {})
        @issuer_profile_id = params[:issuer_profile_id]
      end

      def legal_name
        Rails.cache.fetch("#{issuer_profile_id}_legal_name", expires_in: 2.days) do
          BenefitSponsors::Organizations::ExemptOrganization.by_profile_id(issuer_profile_id).first.legal_name
        end
      end

      def retrieve_table_data
        @retrieve_table_data ||= ::BenefitMarkets::Products::Product.by_issuer_profile_id(issuer_profile_id)
      end
    end
  end
end
