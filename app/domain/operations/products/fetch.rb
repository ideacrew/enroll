# frozen_string_literal: true

module Operations
  module Products
    # This class is to fetch product premiums for given family & effective date
    # This considers rating address for each person in the given family & gives lcsp details for all the family members at given address.
    class Fetch
      include Dry::Monads[:result, :do]


      # @param [Date] effective_date
      # @param [Family] family
      # @param [Family Member Id] family member id - to get specific family members lcsp.

      def call(params)
        values                     = yield validate(params)
        addresses                  = yield find_addresses(values[:family])
        rating_silver_products     = yield fetch_silver_products(addresses, values[:effective_date], values[:family])
        member_premiums            = yield fetch_member_premiums(rating_silver_products, values[:family], values[:effective_date])

        Success(member_premiums)
      end

      private

      def validate(params)
        return Failure('Missing Family') if params[:family].blank?
        return Failure('Missing Effective Date') if params[:effective_date].blank?
        return Failure("Unable to find rating addresses for at least one family member for given family with id: #{params[:family].id}") unless all_members_have_valid_address?(params[:family])
        Success(params)
      end

      # Return a failure monad if there are no rating addresses for any members
      def all_members_have_valid_address?(family)
        family.family_members.all? { |family_member| family_member.rating_address.present? }
      end

      def find_addresses(family)
        geographic_rating_area_model = EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model).item
        members = family.family_members.where(is_primary_applicant: true, is_active: true)

        address_combinations = case geographic_rating_area_model
                               when 'single'
                                 members.group_by {|fm| [fm.rating_address.state]}
                               when 'county'
                                 members.group_by {|fm| [fm.rating_address.county]}
                               when 'zipcode'
                                 members.group_by {|fm| [fm.rating_address.zip]}
                               else
                                 members.group_by {|fm| [fm.rating_address.county, fm.rating_address.zip]}
                               end

        address_combinations = address_combinations.transform_values {|v| v.map(&:rating_address).compact }.values

        Success(address_combinations)
      end

      def fetch_silver_products(addresses, effective_date, family)
        silver_products = Operations::Products::FetchSilverProducts.new.call({address: addresses.flatten[0], effective_date: effective_date})
        return Failure("unable to fetch silver_products for - #{addresses.flatten[0]}") if silver_products.failure?

        Success({family.active_family_members.collect{|fm| fm.person.hbx_id} => silver_products.value!})
      end

      def fetch_member_premiums(rating_silver_products, family, effective_date)
        member_premiums = {}
        min_age = family.family_members.map {|fm| fm.age_on(TimeKeeper.date_of_record) }.min

        rating_silver_products.each_pair do |hbx_ids, payload|
          member_premiums[hbx_ids] = {}

          health_products = payload[:products].where(kind: :health)
          premiums = Operations::Products::FetchSilverProductPremiums.new.call({products: health_products, dental_products: [], family: family, effective_date: effective_date, rating_area_id: payload[:rating_area_id], slcsp_type: :health_only})

          return Failure("unable to fetch health only premiums for - #{hbx_ids}") if premiums.failure?
          member_premiums[hbx_ids][:health_only] = premiums.value!


          dental_products = payload[:products].select { |product| product.allows_adult_and_child_only_offering? && product.age_based_rating? }
          premiums = Operations::Products::FetchSilverProductPremiums.new.call({products: health_products, dental_products: dental_products, family: family, effective_date: effective_date, rating_area_id: payload[:rating_area_id],
                                                                                slcsp_type: :health_and_dental})

          return Failure("unable to fetch health_and_dental premiums for - #{hbx_ids}") if premiums.failure?
          member_premiums[hbx_ids][:health_and_dental] = premiums.value!

          dental_products = payload[:products].select { |product| product.allows_child_only_offering? && product.age_based_rating? }
          premiums = Operations::Products::FetchSilverProductPremiums.new.call({products: health_products, dental_products: dental_products, family: family, effective_date: effective_date, rating_area_id: payload[:rating_area_id],
                                                                                slcsp_type: :health_and_ped_dental})

          return Failure("unable to fetch health_and_ped_dental premiums for - #{hbx_ids}") if premiums.failure?
          member_premiums[hbx_ids][:health_and_ped_dental] = premiums.value!
        end

        Success(member_premiums)
      end
    end
  end
end
