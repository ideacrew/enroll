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
        result = ::Operations::PremiumCredits::FindAll.new.call({ family: @hbx_enrollment.family, year: @effective_on.year, kind: 'aptc_grant' })

        return true if result.failure?

        @aptc_grants = result.value!

        return true if @aptc_grants.blank?
        return true if (@aptc_grants.map(&:member_ids).flatten.uniq & enrolled_family_member_ids).blank?

        false
      end

      def available_aptc
        available_aptc_hash.values.sum - utilized_aptc
        # aptc = available_aptc_hash.values.sum - utilized_aptc

        # [aptc, @hbx_enrollment.total_ehb_premium].min
      end

      def utilized_aptc
        return 0.0 if active_enrollments.blank?

        @hbx_enrollment.generate_hbx_signature

        active_enrollments.reject do |previous_enrollment|
          previous_enrollment.generate_hbx_signature
          previous_enrollment.enrollment_signature == @hbx_enrollment.enrollment_signature
        end.sum(&:applied_premium_credit).to_f
      end

      def available_aptc_hash
        @aptc_grants.where(:member_ids.in => enrolled_family_member_ids).inject({}) do |result, aptc_grant|
          available_aptc = current_max_aptc_hash[aptc_grant.id] - benchmark_premium_of_non_enrolling(aptc_grant)
          available_aptc = (available_aptc > 0.0) ? available_aptc : 0.0
          result[aptc_grant.id] = available_aptc
          result
        end
      end

      def current_max_aptc_hash
        @aptc_grants.where(:member_ids.in => enrolled_family_member_ids).inject({}) do |result, aptc_grant|
          result[aptc_grant.id] = aptc_grant.value
          result
        end
      end

      def enrolled_family_member_ids
        @hbx_enrollment.hbx_enrollment_members.map(&:applicant_id).map(&:to_s)
      end

      def aptc_eligible_non_enrolled_family_members_without_active_enrollment(aptc_grant)
        aptc_eligible_non_enrolled_family_member_ids = aptc_grant.member_ids - enrolled_family_member_ids

        return aptc_eligible_non_enrolled_family_member_ids if active_enrollments.blank?

        aptc_eligible_non_enrolled_family_member_ids - active_enrollments.map(&:hbx_enrollment_members).flatten.map(&:applicant_id).uniq
      end

      def active_enrollments
        @active_enrollments ||= @family.active_household.hbx_enrollments.enrolled.individual_market
      end

      def benchmark_premium_of_non_enrolling(aptc_grant)
        aptc_eligible_non_enrolled_family_members_without_active_enrollment(aptc_grant).reduce(0) do |_sum, member_id|
          # TODO: use benchmark_premiums method instead of instance variable.
          @benchmark_premiums[member_id][:premium]
        end
      end

      def benchmark_premiums
        # We're going to persist these values.
        # We're going to mock for the time being.

        @benchmark_premiums = @family.family_members.inject({}) do |result, family_member|
          result[family_member.id] = { premium: 0.0 }
          result
        end
      end
    end
  end
end
