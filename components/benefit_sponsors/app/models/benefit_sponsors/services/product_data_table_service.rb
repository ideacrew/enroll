 # frozen_string_literal: true

module BenefitSponsors
  module Services
    class ProductDataTableService
      attr_accessor :issuer_profile_id, :filter

      def initialize(params = {})
        @issuer_profile_id = params[:issuer_profile_id]
        @filter = params[:filter].to_i
      end

      def legal_name
        Rails.cache.fetch("#{issuer_profile_id}_legal_name", expires_in: 2.days) do
          BenefitSponsors::Organizations::ExemptOrganization.by_profile_id(issuer_profile_id).first.legal_name
        end
      end

      def not_all?
        filter.present? && filter != 0
      end

      def retrieve_table_data
        records = ::BenefitMarkets::Products::Product.by_issuer_profile_id(issuer_profile_id)
        not_all? ? records.by_year(filter) : records
      end
    end
  end
end
