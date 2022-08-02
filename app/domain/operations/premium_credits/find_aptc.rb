# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module PremiumCredits
    # This operation is to find Max Aptc
    class FindAptc
      include Dry::Monads[:result, :do]

      def call(params)
        values = yield validate(params)
        result = yield find_max_available_aptc(values)

        Success(result)
      end

      private

      def validate(params)
        return Failure('Invalid params. hbx_enrollment should be an instance of Hbx Enrollment') unless params[:hbx_enrollment].is_a?(HbxEnrollment)
        return Failure('Missing effective_on') unless params[:effective_on]

        Success(params)
      end

      def find_max_available_aptc(values)
        @hbx_enrollment = values[:hbx_enrollment]
        @effective_on = values[:effective_on]
        @family = @hbx_enrollment.family

        return Success(0.0) if not_eligible?

        Success(available_aptc)
      end

      def not_eligible?
        result = ::Operations::PremiumCredits::FindAll.new.call({ family: @hbx_enrollment.family, year: @effective_on.year, kind: 'aptc_csr' })

        return true if result.failure?

        @group_premium_credits = result.value!

        return true if @group_premium_credits.blank?
        return true if (@group_premium_credits.map(&:member_premium_credits).flatten.map(&:family_member_id).uniq && enrolled_family_member_ids).blank?

        false
      end

      def available_aptc
        available_aptc_hash.values.sum
      end

      def available_aptc_hash
        @group_premium_credits.where(:"member_premium_credits.family_member_id".in => enrolled_family_member_ids).inject({}) do |result, group_premium_credit|
          available_aptc = current_max_aptc_hash[group_premium_credit.id] - benchmark_premium_of_non_enrolling(group_premium_credit)
          available_aptc = (available_aptc > 0.0) ? available_aptc : 0.0
          result[group_premium_credit.id] = available_aptc
          result
        end
      end

      def current_max_aptc_hash
        @group_premium_credits.where(:"member_premium_credits.family_member_id".in => enrolled_family_member_ids).inject({}) do |result, group_premium_credit|
          result[group_premium_credit.id] = group_premium_credit.premium_credit_monthly_cap
          result
        end
      end

      def enrolled_family_member_ids
        @hbx_enrollment.hbx_enrollment_members.map(&:applicant_id)
      end

      def aptc_eligible_non_enrolled_family_members_without_active_enrollment(group_premium_credit)
        active_enrollments = @family.active_household.hbx_enrollments.enrolled

        aptc_eligible_non_enrolled_family_member_ids = group_premium_credit.member_premium_credits.map(&:family_member_id).uniq - enrolled_family_member_ids

        return aptc_eligible_non_enrolled_family_member_ids if active_enrollments.blank?

        aptc_eligible_non_enrolled_family_member_ids - active_enrollments.map(&:hbx_enrollment_members).flatten.map(&:applicant_id).uniq
      end

      def benchmark_premium_of_non_enrolling(group_premium_credit)
        aptc_eligible_non_enrolled_family_members_without_active_enrollment(group_premium_credit).reduce(0) do |_sum, member_id|
          # TODO: use benchmark_premiums method instead of instance variable.
          @benchmark_premiums[member_id][:premium]
        end
      end

      def benchmark_premiums
        # We're going to persist these values.
        # We're going to mock for the time being.

        @benchmark_premiums = []
      end
    end
  end
end
