# frozen_string_literal: true

module Operations
  module Products
    # This class is to fetch silver product premiums for given products, family, effective date, rating area id.
    class FetchSlcspPremiumForTaxHouseholdMember
      include Dry::Monads[:result, :do]

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
        age = family_member.age_on(effective_date)
        # age = ::Operations::AgeLookup.new.call(age).success if false && age_rated # TODO - Get age_rated through settings
        cost_product_hash =
          products.inject([]) do |result, product|
            premium_table = product.premium_tables.where(
              {
                :rating_area_id => rating_area_id,
                :'effective_period.min'.lte => effective_date,
                :'effective_period.max'.gte => effective_date
              }
            ).first

            tuple = premium_table.premium_tuples.where(age: age).first
            result << { cost: tuple.cost, product_id: product.id } if tuple.present?
            result
          end

        sorted_product_hash = cost_product_hash.sort_by { |tuple_hash| tuple_hash[:cost] }
        result = sorted_product_hash[1] || sorted_product_hash[0]

        if result
          Success(result)
        else
          Failure("Unable to determine SLCSP premium for tax_household_member: #{tax_household_member.id} for effective_date: #{effective_date} and rating_area: #{rating_area_id}")
        end
      end
    end
  end
end
