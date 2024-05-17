# frozen_string_literal: true

module Operations
  module Products
    # This class is to fetch silver product premiums for given products, family, effective date, rating area id.
    class FetchSlcspPremiumForTaxHouseholdMember
      include Dry::Monads[:do, :result]

      # @param [Date] effective_date
      # @param [RatingArea] rating_area_id
      # @param [TaxHouseholdMember] tax_household_member
      # @param [Product] products
      def call(params)
        values            = yield validate(params)
        product_premiums  = yield fetch_product_premiums(values[:products], values[:tax_household_member], values[:effective_date], values[:rating_area_id].to_s)

        Success(product_premiums)
      end

      private

      def validate(params)
        return Failure('Missing Products') if params[:products].blank?
        return Failure('Missing TaxHouseholdMember') if params[:tax_household_member].blank?
        return Failure('Missing Effective Date') if params[:effective_date].blank?
        return Failure('Missing rating area id') if params[:rating_area_id].blank?

        Success(params)
      end

      def fetch_product_premiums(products, tax_household_member, effective_date, rating_area_id)
        family_member = tax_household_member.family_member

        product_hash = Operations::Products::FetchSilverProductPremiums.new.call(
          {
            products: products,
            family: tax_household_member.family,
            family_member_id: family_member.id,
            effective_date: effective_date,
            rating_area_id: rating_area_id
          }
        )

        if product_hash.success? && product_hash.success[family_member.hbx_id]
          values = product_hash.success[family_member.hbx_id]
          Success(values[1] || values[0])
        else
          Failure("Unable to determine SLCSP premium for tax_household_member: #{tax_household_member.id} for effective_date: #{effective_date} and rating_area: #{rating_area_id}")
        end
      end
    end
  end
end
