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
        renew_individual(payload)

        ack(delivery_info.delivery_tag)
      rescue StandardError, SystemStackError => e
        @logger.error "OpenEnrollmentSubscriber, payload: #{payload}, error message: #{e.message}, backtrace: #{e.backtrace}"
        @logger.error "OpenEnrollmentSubscriber, ack: #{payload}"
        ack(delivery_info.delivery_tag)
      end

      private

      def renew_individual(payload)
        id = GlobalID::Locator.locate(payload[:gid]).id

        if renewal_bcp.eligibility_for("aca_ivl_osse_eligibility_#{renewal_effective_on.year}".to_sym, renewal_effective_on)
          renew_person(id)
        else
          renew_family(id)
        end
      rescue StandardError => e
        @logger.error "Error: OpenEnrollmentSubscriber, payload: #{payload}; response: #{e}"
      end

      def renew_family(id)
        renew_enrollments(Family.find(id))
      end

      def renew_person(id)
        person = Person.find(id)
        role = fetch_role(person)
        return if role.blank?

        skip_callbacks
        result = renew_osse_eligibility(role)

        if result.success?
          @logger.info "Renewed OSSE eligibility: #{person.hbx_id}"
          family = person.primary_family
          renew_enrollments(family) if family
        else
          @logger.info "Failed Osse Renewal: #{person.hbx_id}; Error: #{result.failure};"
        end

        set_callbacks
      end

      def renew_enrollments(family)
        query = kollection(HbxEnrollment::COVERAGE_KINDS, current_bcp)
        enrollments = family.active_household.hbx_enrollments.where(query).order(:effective_on.desc)
        enrollments.each do |enrollment|
          result = ::Operations::Individual::RenewEnrollment.new.call(hbx_enrollment: enrollment,
                                                                      effective_on: renewal_effective_on)

          if result.failure?
            @logger.info "Failed Enrollment Renewal: Enrollment: #{enrollment.hbx_id}; Error: #{result.failure};"
          else
            @logger.info "Renewed Enrollment: #{enrollment.hbx_id}"
          end
        end
      end

      def renew_osse_eligibility(role)
        osse_eligibility = role.is_osse_eligibility_satisfied?(renewal_effective_on - 1.day)

        ::Operations::IvlOsseEligibilities::CreateIvlOsseEligibility.new.call(
          {
            subject: role.to_global_id,
            evidence_key: :ivl_osse_evidence,
            evidence_value: osse_eligibility.to_s,
            effective_date: renewal_effective_on
          }
        )
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

      def current_bs
        @current_bs ||= HbxProfile.current_hbx.benefit_sponsorship
      end

      def renewal_bcp
        @renewal_bcp ||= current_bs.renewal_benefit_coverage_period
      end

      def current_bcp
        @current_bcp ||= current_bs.current_benefit_coverage_period
      end

      def renewal_effective_on
        @renewal_effective_on ||= renewal_bcp.start_on
      end

      def kollection(kind, coverage_period)
        {
          :kind.in => ['individual', 'coverall'],
          :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES - ["coverage_renewed", "coverage_termination_pending"]),
          :coverage_kind.in => kind,
          :effective_on => { "$gte" => coverage_period.start_on, "$lt" => coverage_period.end_on}
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
