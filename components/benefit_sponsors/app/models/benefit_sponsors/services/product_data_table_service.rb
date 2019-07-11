 # frozen_string_literal: true

module BenefitSponsors
  module Services
    class ProductDataTableService

      attr_accessor :issuer_profile_id

      def initialize(params = {})
        @issuer_profile_id = params[:issuer_profile_id]
      end

      def retrieve_table_data
        ::BenefitMarkets::Products::Product.by_issuer_profile_id(issuer_profile_id)
      end

    end
  end
end