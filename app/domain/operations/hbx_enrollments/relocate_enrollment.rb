module Operations
  module HbxEnrollments
    # Relocate enrollment operation for SHOP and IVL enrollments based on the given payload
    class RelocateEnrollment
      include Dry::Monads[:result, :do]

      ENROLLMENT_ACTION_MAPPING = {
        "Terminate Enrollment Effective End of the Month" => "terminate_enrollment",
        "Generate Rerated Enrollment with same product ID" => "generate_new_enrollment"
      }.freeze

      # @param [Hash] payload
      # @option payload [String] :expected_enrollment_action
      # @option payload [String] :enrollment_hbx_id
      # @option payload [Boolean] :is_service_area_changed
      # @option payload [Boolean] :product_offered_in_new_service_area
      # @option payload [Boolean] :is_rating_area_changed
      # @option payload [String] :event_outcome
      # @return [Dry::Monads::Result]
      def call(payload)
        valid_params = yield validate(payload)
        enrollment = yield find_enrollment(valid_params)
        result = yield send(ENROLLMENT_ACTION_MAPPING[valid_params[:expected_enrollment_action]], enrollment)

        Success(result)
      end

      private

      def validate(payload)
        return Failure("Expected enrollment action is missing") unless payload[:expected_enrollment_action].present?
        return Failure("Enrollment hbx_id is missing") unless payload[:enrollment_hbx_id].present?

        Success(payload)
      end

      def find_enrollment(payload)
        Operations::HbxEnrollments::Find.new.call({hbx_id: payload[:enrollment_hbx_id]})
      end

      def terminate_enrollment(enrollment)
        Operations::HbxEnrollments::Terminate.new.call({enrollment_hbx_id: enrollment.hbx_id})
      end

      def generate_new_enrollment(enrollment)
        generate_new_enrollment_for_ivl(enrollment) unless enrollment.is_shop?
        generate_new_enrollment_for_shop(enrollment) if enrollment.is_shop?
      end

      def generate_new_enrollment_for_ivl(base_enrollment)
        new_effective_date = Insured::Factories::SelfServiceFactory.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), base_enrollment.effective_on).to_date
        reinstatement = Enrollments::Replicator::Reinstatement.new(base_enrollment, new_effective_date, base_enrollment.applied_aptc_amount).build

        if reinstatement.save!
          result = if base_enrollment.applied_aptc_amount > 0
            default_percentage = EnrollRegistry[:aca_individual_assistance_benefits].setting(:default_applied_aptc_percentage).item
            elected_aptc_pct = base_enrollment.elected_aptc_pct > 0 ? base_enrollment.elected_aptc_pct : default_percentage
            ::Insured::Factories::SelfServiceFactory.mthh_update_enrollment_for_aptcs(new_effective_date, reinstatement, elected_aptc_pct, nil)
          else
            true
          end

          if result == true
            reinstatement.select_coverage!
            return Success({:reinstatement_hbx_id => reinstatement.hbx_id, :reinstatement_aasm_state => reinstatement.aasm_state})
          end
          return result if result.is_a?(Failure)
          Failure(result)
        else
          Failure(reinstatement.errors.full_messages)
        end
      end

      def generate_new_enrollment_for_shop(enrollment); end
    end
  end
end