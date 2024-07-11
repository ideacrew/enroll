# frozen_string_literal: true

module Operations
  module Products
    # This class is to fetch silver product premiums for given products, family, effective date, rating area id.
    class FetchSilverProductPremiums
      include Dry::Monads[:do, :result]

      # @param [Date] effective_date
      # @param [RatingArea] rating_area_exchange_provided_code
      # @param [Family] family
      # @param [Product] products
      # @param [FamilyMember] family_member_id Passing in family_member_id will only return premiums for that particular member
      def call(params)
        values            = yield validate(params)
        family_members    = yield fetch_family_members(values[:family], values[:family_member_id])
        product_premiums  = yield fetch_product_premiums(values[:products], family_members, values[:effective_date], values[:rating_area_exchange_provided_code].to_s)

        Success(product_premiums)
      end

      private

      def validate(params)
        return Failure('Missing Products') if params[:products].blank?
        return Failure('Missing Family') if params[:family].blank?
        return Failure('Missing Effective Date') if params[:effective_date].blank?
        return Failure('Missing rating area id') if params[:rating_area_exchange_provided_code].blank?

        Success(params)
      end

      def fetch_family_members(family, family_member_id)
        members = family.family_members
        family_members = members.active
        family_members = members.where(id: BSON::ObjectId(family_member_id)) if family_member_id

        if family_members.present?
          Success(family_members)
        else
          Failure("Unable to find family members for the given family: #{family.id} & family_member_id: #{family_member_id}")
        end
      end

      def fetch_product_premiums(products, family_members, effective_date, rating_area_exchange_provided_code)
        member_premiums = family_members.inject({}) do |member_result, family_member|
          age = family_member.age_on(effective_date)
          hbx_id = family_member.hbx_id
          # age = ::Operations::AgeLookup.new.call(age).success if false && age_rated # Todo - Get age_rated through settings
          product_hash =
            products.inject([]) do |result, product|
              variant_id = product.hios_id.split('-')[1]
              next result if variant_id.present? && variant_id != '01'
              cost = ::BenefitMarkets::Products::ProductRateCache.lookup_rate(product, effective_date, age, rating_area_exchange_provided_code)

              result << { cost: (cost * product.ehb).round(2), product_id: product.id, member_identifier: hbx_id, monthly_premium: (cost * product.ehb).round(2) } if cost.present?

              result
            end
          member_result[hbx_id] = product_hash.sort_by {|tuple_hash| tuple_hash[:cost]}

          member_result
        end
        Success(member_premiums)
      end
    end
  end
end
