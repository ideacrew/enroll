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
      # @param [FamilyMember] family_member_id Passing in family_member_id will only return premiums for that particular member
      def call(params)
        values            = yield validate(params)
        family_members    = yield fetch_family_members(values[:family], values[:family_member_id])
        product_premiums  = yield fetch_product_premiums({products: values[:products], dental_products: values[:dental_products], family_members: family_members, effective_date: values[:effective_date], rating_area_id: values[:rating_area_id].to_s})

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

      def fetch_family_members(family, family_member_id)
        family_members = family.family_members.active
        family_members = family.family_members.where(id: BSON::ObjectId(family_member_id)) if family_member_id

        if family_members.present?
          Success(family_members)
        else
          Failure("Unable to find family members for the given family: #{family.id} & family_member_id: #{family_member_id}")
        end
      end

      def fetch_product_premiums(attrs)
        member_premiums = attrs[:family_members].inject({}) do |member_result, family_member|
          age = family_member.age_on(attrs[:effective_date])
          attrs[:slcsp_type] = :health_only if age > 18
          hbx_id = family_member.hbx_id
          sldp = second_lowest_dental_product_premium(attrs[:dental_products], attrs[:effective_date], attrs[:rating_area_id], age)
          # age = ::Operations::AgeLookup.new.call(age).success if false && age_rated # Todo - Get age_rated through settings
          product_hash =
            attrs[:products].inject([]) do |result, product|
              variant_id = product.hios_id.split('-')[1]
              next result if variant_id.present? && variant_id != '01'
              premium_table = product.premium_tables.where({
                                                             :rating_area_id => attrs[:rating_area_id],
                                                             :'effective_period.min'.lte => attrs[:effective_date],
                                                             :'effective_period.max'.gte => attrs[:effective_date]
                                                           }).first

              tuple = premium_table.premium_tuples.where(age: age).first || set_tuple(premium_table, age)

              if tuple.present?
                cost = product_premium(product, tuple, attrs[:slcsp_type], sldp)
                result << { cost: cost, product_id: product.id, member_identifier: hbx_id, monthly_premium: cost }
              end

              result
            end
          member_result[hbx_id] = product_hash.sort_by {|tuple_hash| tuple_hash[:cost]}

          member_result
        end
        Success(member_premiums)
      end

      def set_tuple(premium_table, age)
        tuple_ages = premium_table.premium_tuples.map(&:age)
        min_age = tuple_ages.min
        max_age = tuple_ages.max
        age = min_age if age < min_age
        age = max_age if age > max_age
        premium_table.premium_tuples.where(age: age).first
      end

      def product_premium(product, tuple, slcsp_type, sldp)
        return ((tuple.cost * product.ehb) + sldp).round(2) if slcsp_type == :health_and_dental
        return (tuple.cost * product.ehb).round(2) if slcsp_type == :health_only || product.covers_pediatric_dental?
        ((tuple.cost * product.ehb) + sldp).round(2)
      end

      def second_lowest_dental_product_premium(dental_products, effective_date, rating_area_id, age)
        dental_products.inject([]) do |result, dental_product|
          dpt = dental_product.premium_tables.where({
                                                      :rating_area_id => rating_area_id,
                                                      :'effective_period.min'.lte => effective_date,
                                                      :'effective_period.max'.gte => effective_date
                                                    }).first

          dental_tuple = dpt.premium_tuples.where(age: age).first || set_tuple(dpt, age)

          result << dental_tuple.cost * dental_product.pediatric_ehb
          result
        end.sort[1].to_f
      end
    end
  end
end
