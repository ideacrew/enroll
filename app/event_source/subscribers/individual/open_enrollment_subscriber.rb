# frozen_string_literal: true

module Subscribers
  module Individual
    # Subscriber for ivl open enrollment
    class OpenEnrollmentSubscriber
      include ::EventSource::Subscriber[amqp: 'enroll.individual.open_enrollment']

      subscribe(:on_begin) do |delivery_info, _metadata, response|
        @logger = subscriber_logger_for(:on_enroll_individual_open_enrollment_begin)
        payload = JSON.parse(response, symbolize_names: true)
        @logger.info "OpenEnrollmentSubscriber, response: #{payload}"

        id = GlobalID::Locator.locate(payload[:family_gid]).id
        @logger.info "------------ Processing family: #{id}, index_id: #{payload[:index_id]} ------------"
        renew_family(id, payload)
        @logger.info "Processed family: #{id}"

        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        @logger.error "OpenEnrollmentSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
        @logger.error "OpenEnrollmentSubscriber, ack: #{payload}"
        ack(delivery_info.delivery_tag)
      end

      private

      def renew_family(id, payload)
        @renewal_effective_on = payload[:renewal_effective_on].to_date
        @current_start_on = payload[:current_start_on].to_date
        @current_end_on = payload[:current_end_on].to_date
        family = Family.find(id)

        @logger.info "Processing family with bson_id: #{id} for OSSE"
        if payload[:osse_enabled]
          results = family.family_members.active.collect do |family_member|
            person = family_member.person
            renew_osse_eligibility(person)
          end
        end

        if results&.compact&.any? {|result| result.failure? }
          @logger.info "Skipping enrollment renewal as it failed Osse Renewal: #{family.hbx_assigned_id};"
          return
        end
        @logger.info "Processed family with bson_id: #{id} for OSSE"

        @logger.info "Processing family with bson_id: #{id} for Enrollments Renewal"
        renew_enrollments(family)
        @logger.info "Processed family with bson_id: #{id} for Enrollments Renewal"
      rescue StandardError => e
        @logger.error "Error: OpenEnrollmentSubscriber, payload: #{payload}; error_message: #{e.message}, backtrace: #{e.backtrace}, inspect: #{e.inspect}"
      end

      def renew_osse_eligibility(person)
        role = fetch_role(person)
        return if role.blank?

        osse_eligibility = role.is_osse_eligibility_satisfied?(TimeKeeper.date_of_record)
        return unless osse_eligibility

        renewal_eligibility = role.eligibility_on(@renewal_effective_on)
        return if renewal_eligibility

        result = ::Operations::IvlOsseEligibilities::CreateIvlOsseEligibility.new.call(
          {
            subject: role.to_global_id,
            evidence_key: :ivl_osse_evidence,
            evidence_value: osse_eligibility.to_s,
            effective_date: @renewal_effective_on
          }
        )

        if result.success?
          @logger.info "Renewed OSSE eligibility: #{person.hbx_id}"
        else
          @logger.info "Failed Osse Renewal: #{person.hbx_id}; Error: #{result.failure};"
        end

        result
      end

      def renew_enrollments(family)
        query = kollection(HbxEnrollment::COVERAGE_KINDS)
        enrollments = family.active_household.hbx_enrollments.where(query).order(:effective_on.desc)
        enrollments.each do |enrollment|
          result = ::Operations::Individual::RenewEnrollment.new.call(
            hbx_enrollment: enrollment,
            effective_on: @renewal_effective_on
          )

          if result.failure?
            @logger.info "Failed Enrollment Renewal: Enrollment: #{enrollment.hbx_id}; Error: #{result.failure};"
          else
            @logger.info "Renewed Enrollment: #{enrollment.hbx_id}"
          end
        end
      end

      def skip_callbacks
        ConsumerRole.skip_callback(:update, :after, :publish_updated_event)
        ConsumerRole.skip_callback(:validation, :before, :ensure_verification_types)
        ConsumerRole.skip_callback(:validation, :before, :ensure_validation_states)
      end

      def set_callbacks
        ConsumerRole.set_callback(:update, :after, :publish_updated_event)
        ConsumerRole.set_callback(:validation, :before, :ensure_verification_types)
        ConsumerRole.set_callback(:validation, :before, :ensure_validation_states)
      end

      def kollection(coverage_kinds)
        {
          :kind.in => ['individual', 'coverall'],
          :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES - ["coverage_renewed", "coverage_termination_pending"]),
          :coverage_kind.in => coverage_kinds,
          :effective_on => { "$gte" => @current_start_on, "$lt" => @current_end_on }
        }
      end

      def fetch_role(person)
        if person.has_active_resident_role?
          person.resident_role
        elsif person.has_active_consumer_role?
          person.consumer_role
        end
      end

      def subscriber_logger_for(event)
        Logger.new(
          "#{Rails.root}/log/#{event}_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
        )
      end
    end
  end
end
