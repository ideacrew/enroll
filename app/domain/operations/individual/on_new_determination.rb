# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Individual
    # Create new enrollments based on new eligibility determination
    class OnNewDetermination
      include Dry::Monads[:result, :do]
      include FloatHelper

      def call(params)
        values = yield validate(params)
        eligible_enrollments    = yield fetch_enrollments_to_renew(values)
        generate_enrollments    = yield generate_enrollments(eligible_enrollments)
        Success(generate_enrollments)
      end

      private

      def validate(params)
        return Failure("Missing Family") unless params[:family].is_a?(Family)
        return Failure("Missing Year") if params[:year].blank?

        Success(params)
      end

      def fetch_enrollments_to_renew(values)
        enrollments = values[:family].active_household.hbx_enrollments.enrolled_and_renewal.individual_market.by_health.by_year(values[:year])
        return Failure('Cannot find any IVL health enrollments in any of the active states.') if enrollments.blank?

        enrollment_list = enrollments.reject do |enrollment|
          enrollment.product.blank? || enrollment.product.metal_level_kind == :catastrophic
        end
        enrollment_list.present? ? Success(enrollment_list) : Failure('Cannot find any enrollments with Non-Catastrophic Plan.')
      end

      def generate_enrollments(enrollments)
        enrollments.each do |enrollment|
          date = Insured::Factories::SelfServiceFactory.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), enrollment.effective_on).to_date

          result = ::Operations::PremiumCredits::FindAptc.new.call({
                                                                     hbx_enrollment: enrollment,
                                                                     effective_on: date
                                                                   })
          return result unless result.success?

          max_aptc = result.value!
          default_percentage = EnrollRegistry[:aca_individual_assistance_benefits].setting(:default_applied_aptc_percentage).item
          applied_percentage = enrollment.elected_aptc_pct > 0 ? enrollment.elected_aptc_pct : default_percentage
          applied_aptc = float_fix(max_aptc * applied_percentage)

          attrs = {
            enrollment_id: enrollment.id,
            elected_aptc_pct: applied_percentage,
            aptc_applied_total: applied_aptc,
            aggregate_aptc_amount: max_aptc
          }


          ::Insured::Forms::SelfTermOrCancelForm.for_aptc_update_post(attrs)
        end
        Success("Aggregate amount applied on to enrollments")
      end
    end
  end
end
