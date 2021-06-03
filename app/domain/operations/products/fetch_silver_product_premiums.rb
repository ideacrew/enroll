# frozen_string_literal: true

module Operations
  module Products
    # This class is to fetch silver product premiums for given products, family, effective date, rating area id.
    class FetchSilverProductPremiums
      include Dry::Monads[:result, :do]

      # @param [Date] effective_date
      # @param [RatingArea] rating_area_id
      # @param [Family] family
      # @param [Product] products
      def call(params)
        values            = yield validate(params)
        product_premiums  = yield fetch_product_premiums(values[:products], values[:family], values[:effective_date], values[:rating_area_id].to_s)

        Success(product_premiums)
      end

      private

      def validate(params)
        return Failure('Missing Products') if params[:products].blank?
        return Failure('Missing Family') if params[:family].blank?
        return Failure('Missing Effective Date') if params[:effective_date].blank?
        return Failure('Missing rating area id') if params[:rating_area_id].blank?

        Success(params)
      end

      def fetch_product_premiums(products, family, effective_date, rating_area_id)
        member_premiums = family.family_members.active.inject({}) do |member_result, family_member|
          age = family_member.age_on(effective_date)
          age = ::Operations::AgeLookup.new.call(age).success if false && age_rated # Todo - Get age_rated through settings

          member_result[family_member.id.to_s] = products.inject([]) do |result, product|
            premium_table = product.premium_tables.where({
                                                           :rating_area_id => rating_area_id,
                                                           :'effective_period.min'.lte => effective_date,
                                                           :'effective_period.max'.gte => effective_date
                                                         }).first

            tuple = premium_table.premium_tuples.where(age: age).first
            result << { cost: tuple.cost, product_id: product.id } if tuple.present?
            result
          end.sort_by {|tuple_hash| tuple_hash[:cost]}

          member_result
        end
        Success(member_premiums)
      end
    end
  end
end
