# frozen_string_literal: true

module Operations
  module Products
    # This class is to fetch second lowest cost silver plan for a given tax household member.
    class DetermineSlcspForTaxHouseholdMember
      include Dry::Monads[:do, :result]


      # @param [Date] effective_date
      # @param [TaxHouseholdMember] tax_household_member - to get specific tax_household_member's slcsp
      def call(params)
        values                      = yield validate(params)
        member_hash                 = yield construct_member_hash(values[:tax_household_member], values[:effective_date])
        address                     = yield find_address(member_hash)
        rating_silver_products_hash = yield fetch_silver_products(address, values[:effective_date])
        member_premium              = yield fetch_member_premium(rating_silver_products_hash, values[:tax_household_member], values[:effective_date])

        Success(member_premium)
      end

      private

      def validate(params)
        return Failure('Missing Effective Date') if params[:effective_date].blank?
        return Failure('Missing Tax Household Member') if params[:tax_household_member].blank?
        return Failure('Missing Family for the given TaxHouseholdMember') if params[:tax_household_member].family.blank?
        return Failure('Missing PrimaryPerson for the given TaxHouseholdMember') if params[:tax_household_member].family.primary_person.blank?

        Success(params)
      end

      def is_ia_eligible?(family_member, tax_household_member)
        aptc_tax_household_members = tax_household_member.tax_household.aptc_members
        aptc_member = aptc_tax_household_members.detect { |aptc_tax_household_member| aptc_tax_household_member.applicant_id == family_member.id }
        !!aptc_member&.is_ia_eligible
      end

      def construct_member_hash(tax_household_member, effective_date)
        family_members = tax_household_member.family.family_members

        output = family_members.inject({}) do |member_hash, family_member|
          person = family_member.person
          member_hash[person.id] = {}
          member_hash[person.id].store(:is_primary, family_member.is_primary_applicant?)
          member_hash[person.id].store(:age, person.age_on(effective_date))
          member_hash[person.id].store(:address, person.rating_address)
          member_hash[person.id].store(:tax_household_member, family_member)
          member_hash[person.id].store(:is_ia_eligible, is_ia_eligible?(family_member, tax_household_member))
          member_hash
        end

        Success(output)
      end

      def find_address(member_hash)
        primary_member_hash = member_hash.detect { |_k, v| v[:is_primary] }
        geographic_rating_area_model = EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model).item
        return primary_member_hash[:address] if geographic_rating_area_model == :single

        address =
          if primary_member_hash[1][:is_ia_eligible]
            primary_member_hash[1][:address]
          else
            younger_member_hash = member_hash.min_by { |_k, v| v[:age] }
            older_member_hash = member_hash.max_by { |_k, v| v[:age] }
            if member_hash.detect { |_k, v| v[:is_ia_eligible] && v[:age] > 20 }
              older_member_hash[1][:address]
            else
              younger_member_hash[1][:address]
            end
          end

        if address
          Success(address)
        else
          Failure("Unable to determine address to calc SLCSP for primary_person: #{primary_member_hash[0]}")
        end
      end

      def fetch_silver_products(address, effective_date)
        silver_products = Operations::Products::FetchSilverProducts.new.call({address: address, effective_date: effective_date})
        if silver_products.success?
          silver_products
        else
          Failure("unable to fetch silver_products for give effective_date: #{effective_date},  county: #{address.county}, zip: #{address.zip}")
        end
      end

      def fetch_member_premium(rating_silver_products_hash, tax_household_member, effective_date)
        # TODO: Update to fetch slcsp based on business rule
        # TODO: For now exchange has health products only
        # family = tax_household_member.family
        # min_age = family.family_members.map {|fm| fm.age_on(TimeKeeper.date_of_record) }.min
        # benchmark_product_model = EnrollRegistry[:enroll_app].setting(:benchmark_product_model).item

        health_products = rating_silver_products_hash[:products].where(kind: :health)
        premium_hash = Operations::Products::FetchSlcspPremiumForTaxHouseholdMember.new.call(
          {
            products: health_products,
            effective_date: effective_date,
            rating_area_id: rating_silver_products_hash[:rating_area_id],
            tax_household_member: tax_household_member
          }
        )

        if premium_hash.success?
          premium_hash
        else
          Failure("unable to fetch health only premiums for tax_household_member #{tax_household_member.id} for effective_date: #{effective_date}")
        end
      end
    end
  end
end
