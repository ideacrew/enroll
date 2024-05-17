# frozen_string_literal: true

module Operations
  module HbxEnrollments
    # Relocate enrollment operation for SHOP and IVL enrollments based on the given payload
    class RelocateEnrollment
      include Dry::Monads[:do, :result]

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
       # For Terminated only Success({base_enrollment: {:hbx_id => 123, :aasm_state => 'coverage_terminated', :coverage_kind => 'health'}})
       # For Add/Term Success({base_enrollment: {:hbx_id => 123, :aasm_state => 'coverage_terminated', :coverage_kind => 'health'}, :relocated_enrollment => {:hbx_id => 456, :aasm_state => 'coverage_selected', :coverage_kind => 'health'}})
      def call(payload)
        valid_params = yield validate(payload)
        enrollment = yield find_enrollment(valid_params)
        result = yield send(ENROLLMENT_ACTION_MAPPING[valid_params[:expected_enrollment_action]]&.to_sym, enrollment)

        # TODO: Uncomment below lines once enrollment_relocated event is ready
        # build_and_publish_enrollment_relocated_event(result)

        Success(result)
      end

      private

      def validate(payload)
        return Failure("RelocateEnrollment: Expected enrollment action is missing") unless payload[:expected_enrollment_action].present?
        return Failure("RelocateEnrollment: Enrollment hbx_id is missing") unless payload[:enrollment_hbx_id].present?

        Success(payload)
      end

      def find_enrollment(payload)
        Operations::HbxEnrollments::Find.new.call({hbx_id: payload[:enrollment_hbx_id]})
      end

      def terminate_enrollment(enrollment)
        result = Operations::HbxEnrollments::Terminate.new.call({enrollment_hbx_id: enrollment.hbx_id})
        return result if result.failure?

        Success({base_enrollment: result.success})
      end

      def generate_new_enrollment(enrollment)
        if enrollment.is_shop?
          generate_new_enrollment_for_shop(enrollment)
        elsif enrollment.kind == "individual"
          generate_new_enrollment_for_ivl(enrollment)
        end
      end

      def generate_new_enrollment_for_ivl(base_enrollment)
        date_context = ::HbxEnrollments::CalculateEffectiveOnForEnrollment.call(base_enrollment_effective_on: base_enrollment.effective_on, system_date: TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'))
        return Failure(date_context.message) if date_context.failure?

        new_effective_date = date_context.new_effective_on.to_date
        reinstatement = Enrollments::Replicator::Reinstatement.new(base_enrollment, new_effective_date, base_enrollment.applied_aptc_amount).build

        if reinstatement.save!
          result = if reinstatement.is_health_enrollment? && base_enrollment.has_aptc? && EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
                     default_percentage = EnrollRegistry[:aca_individual_assistance_benefits].setting(:default_applied_aptc_percentage).item
                     elected_aptc_pct = base_enrollment.elected_aptc_pct > 0 ? base_enrollment.elected_aptc_pct : default_percentage
                     aptc_context = ::HbxEnrollments::UpdateMthhAptcValuesOnEnrollment.call(enrollment: reinstatement, elected_aptc_pct: elected_aptc_pct, new_effective_date: reinstatement.effective_on)
                     aptc_context.success? ? true : aptc_context.message
                   else
                     true
                   end

          if result == true
            reinstatement.select_coverage!
            result_hash = build_result_hash(base_enrollment, reinstatement)
            Success(result_hash)
          else
            Failure([result, "reinstatement_shopping_enrollment: #{reinstatement}"])
          end
        else
          Failure(reinstatement.errors.full_messages)
        end
      end

      def build_result_hash(base_enrollment, reinstatement)
        hash = {}
        hash[:base_enrollment] = {:hbx_id => base_enrollment.hbx_id,
                                  :aasm_state => base_enrollment.aasm_state,
                                  :coverage_kind => base_enrollment.coverage_kind,
                                  :kind => base_enrollment.kind,
                                  :applied_aptc_amount => base_enrollment.applied_aptc_amount&.to_f}
        hash.merge!(:relocated_enrollment => {:hbx_id => reinstatement.hbx_id,
                                              :aasm_state => reinstatement.aasm_state,
                                              :coverage_kind => reinstatement.coverage_kind,
                                              :kind => reinstatement.kind,
                                              :applied_aptc_amount => reinstatement.applied_aptc_amount&.to_f})
        hash
      end

      # TODO: Implement this method for emitting events once enrollment_relocation is done
      # families.individual_market.hbx_enrollments.dental_product_terminated
      # families.individual_market.hbx_enrollments.health_product_terminated
      # families.individual_market.hbx_enrollments.dental_product_relocated
      # families.individual_market.hbx_enrollments.health_product_relocated
      def build_and_publish_enrollment_relocated_event(enrollments_hash)
        enrollments_hash.each do |k,v|
          event_key = if v[:coverage_kind] == "health" && v[:aasm_state] == "coverage_terminated"
                        "health_product_terminated"
                      elsif v[:coverage_kind] == "dental" && v[:aasm_state] == "coverage_terminated"
                        "dental_product_terminated"
                      elsif v[:coverage_kind] == "health" && v[:aasm_state] == "coverage_selected"
                        "health_product_relocated"
                      elsif v[:coverage_kind] == "dental" && v[:aasm_state] == "coverage_selected"
                        "dental_product_relocated"
                      end

          event_payload = build_event_payload(enrollments_hash[k], event_key)

          publish_event(event_payload)
        end
        Success(enrollments_hash)
      end

      def publish_event(payload)
        ::Operations::Events::BuildAndPublish.new.call(payload)
      end

      def build_event_payload(payload, event_key)
        headers = { correlation_id: payload[:hbx_id] }

        {event_name: "events.families.individual_market.hbx_enrollments.#{event_key}", attributes:  payload.to_h, headers: headers}
      end

      # TODO: Implement this method for SHOP enrollments
      def generate_new_enrollment_for_shop(_enrollment)
        Success()
      end
    end
  end
end