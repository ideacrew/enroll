# frozen_string_literal: true

module Subscribers
  # To receive payloads for Renew enrollment
  class RenewEnrollmentSubscriber
    include Acapi::Notifiers

    def self.worker_specification
      Acapi::Amqp::WorkerSpecification.new(
        :queue_name => "ivl_enrollment_renewal_subscriber",
        :kind => :direct,
        :routing_key => "info.events.enrollments.renew_enrollment"
      )
    end

    def work_with_params(body, _delivery_info, _properties)
      begin
        payload = JSON.parse(body, :symbolize_names => true)
        family_id = payload[:family_id]
        family = Family.find(family_id.to_s)

        current_bs = HbxProfile.current_hbx.benefit_sponsorship
        renewal_bcp = current_bs.renewal_benefit_coverage_period
        current_bcp = current_bs.current_benefit_coverage_period
        query = kollection(HbxEnrollment::COVERAGE_KINDS, current_bcp)

        enrollments = family.active_household.hbx_enrollments.where(query).order(:effective_on.desc)
        enrollments.each do |enrollment|
          result = ::Operations::Individual::RenewEnrollment.new.call(hbx_enrollment: enrollment,
                                                                      effective_on: renewal_bcp.start_on)
          if result.success?
            notify("acapi.info.events.enrollments.renew_enrollment_success", {:body => JSON.dump({:family_id => family_id, :enrollment_ext_id => enrollment.external_id})})
          else
            notify("acapi.info.events.enrollments.renew_enrollment_failure", {:body => JSON.dump({:family_id => family_id, :enrollment_ext_id => enrollment.external_id})})
          end
        end
      rescue StandardError => _e
        notify("acapi.info.events.enrollments.renew_enrollment_exception", {:body => JSON.dump({:family_id => family_id})})
      end
      :ack
    end

    def kollection(kind, coverage_period)
      {
        :kind.in => ['individual', 'coverall'],
        :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES - ["coverage_renewed", "coverage_termination_pending"]),
        :coverage_kind.in => kind,
        :effective_on => { "$gte" => coverage_period.start_on, "$lt" => coverage_period.end_on}
      }
    end
  end
end

