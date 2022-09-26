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
        enrollment_list.present? ? Success(enrollment_list.sort_by(&:created_at)) : Failure('Cannot find any enrollments with Non-Catastrophic Plan.')
      end

      def generate_enrollments(enrollments)
        exclude_enrollments_list = enrollments.map(&:hbx_id)
        enrollments.each do |enrollment|

          attrs = {
            enrollment_id: enrollment.id,
            exclude_enrollments_list: exclude_enrollments_list
          }

          ::Insured::Forms::SelfTermOrCancelForm.for_aptc_update_post(attrs)
        end
        Success("Aggregate amount applied on to enrollments")
      end
    end
  end
end
