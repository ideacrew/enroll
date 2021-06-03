# frozen_string_literal: true

module Operations
  module Products
    # This class is to fetch second lowest cost silver plan.
    class FetchSlcsp
      include Dry::Monads[:result, :do]


      # @param [Date] effective_date
      # @param [Family] family
      # @param [Family Member Id] family member id - to get specific family members slcsp.

      def call(params)
        values                     = yield validate(params)
        addresses                  = yield find_addresses(values[:family])
        rating_silver_products     = yield fetch_silver_products(addresses, values[:effective_date])
        member_premiums            = yield fetch_member_premiums(rating_silver_products, values[:family], values[:effective_date])
        slcsp_info                 = yield fetch_slcsp_info(member_premiums, values[:family_member])

        Success(slcsp_info)
      end

      private

      def validate(params)
        return Failure('Missing Family') if params[:family].blank?
        return Failure('Missing Effective Date') if params[:effective_date].blank?
        Success(params)
      end

      def find_addresses(family)
        geographic_rating_area_model = EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model).item

        address_combinations = case geographic_rating_area_model
                               when 'single'
                                 family.family_members.active.group_by {|fm| [fm.rating_address.state]}
                               when 'county'
                                 family.family_members.active.group_by {|fm| [fm.rating_address.county]}
                               when 'zipcode'
                                 family.family_members.active.group_by {|fm| [fm.rating_address.zip]}
                               else
                                 family.family_members.active.group_by {|fm| [fm.rating_address.county, fm.rating_address.zip]}
                               end

        address_combinations = address_combinations.transform_values {|v| v.map(&:rating_address).compact }.values

        Success(address_combinations)
      end

      def fetch_silver_products(addresses, effective_date)
        rating_silver_products = addresses.inject({}) do |result, address_combinations|
          silver_products = Operations::Products::FetchSilverProducts.new.call({address: address_combinations.first, effective_date: effective_date})
          if silver_products.success?
            result[address_combinations.map {|add| add.id.to_s }] = silver_products.value!
          else
            return Failure("unable to fetch silver_products for - #{address_combinations}")
          end
          result
        end
        Success(rating_silver_products)
      end

      def fetch_member_premiums(rating_silver_products, family, effective_date)
        member_premiums = {}
        min_age = family.family_members.map {|fm| fm.age_on(TimeKeeper.date_of_record) }.min
        benchmark_product_model = EnrollRegistry[:enroll_app].setting(:benchmark_product_model).item

        rating_silver_products.each_pair do |address_ids, payload|
          member_premiums[address_ids] = {}

          health_products = payload[:products].where(kind: :health)
          premiums = Operations::Products::FetchSilverProductPremiums.new.call({products: health_products, family: family, effective_date: effective_date, rating_area_id: payload[:rating_area_id]})

          if premiums.success?
            member_premiums[address_ids][:health_only] = premiums.value!
          else
            return Failure("unable to fetch health only premiums for - #{address_ids}")
          end

          if benchmark_product_model == :health_and_dental && min_age < 19

            premiums = Operations::Products::FetchSilverProductPremiums.new.call({products: payload[:products], family: family, effective_date: effective_date, rating_area_id: payload[:rating_area_id]})

            if premiums.success?
              member_premiums[address_ids][:health_and_dental] = premiums.value!
            else
              return Failure("unable to fetch health + dental premiums for - #{address_ids}")
            end
          end

          next unless benchmark_product_model == :health_and_ped_dental && min_age < 19
          health_and_ped_dental_products = payload[:products] # TODO: - filter child only ped dental products.

          premiums = Operations::Products::FetchSilverProductPremiums.new.call({products: health_and_ped_dental_products, family: family, effective_date: effective_date, rating_area_id: payload[:rating_area_id]})

          if premiums.success?
            member_premiums[address_ids][:health_and_dental] = premiums.value!
          else
            return Failure("unable to fetch health + dental premiums for - #{address_ids}")
          end
        end

        Success(member_premiums)
      end

      def fetch_slcsp_info(member_premiums, family_member)
        if family_member.present?
          rating_address_id = family_member.rating_address&.id.to_s
          member_values = member_premiums.find {|premiums| (premiums[0].include? rating_address_id) }
          if member_values.blank?
            return Failure('Could Not find any member premiums for the given data')
          else
            # Todo - get for member.
          end
        else
          slcsp_info = member_premiums.each_pair do |_address_ids, premiums|
            premiums.each_pair do |_type, member_values|
              member_values.each_pair do |fm_id, values|
                value = values[1] || values[0]

                member_values[fm_id] = value
              end
            end
          end
        end

        Success(slcsp_info)
      end
    end
  end
end
