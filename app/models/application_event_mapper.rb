class ApplicationEventMapper

  EVENT_MAP = {
      employer_profile: {
          applicant: :created,
# - address_changed
# - contact_changed
# - fein_corrected
# - name_changed
# - broker_added
# - broker_terminated          
        },
      plan_year: {
          published:  :benefit_coverage_initial_application_approved,
          enrolling:  :benefit_coverage_initial_open_enrollment_began,
          enrolled:   :benefit_coverage_initial_open_enrollment_ended,
          draft:      :benefit_coverage_initial_application_reverted,
          renewing_draft:       :benefit_coverage_renewal_application_period_begin,
          renewing_published:   :benefit_coverage_renewal_application_approved,
          renewing_enrolling:   :benefit_coverage_renewal_open_enrollment_began,
          renewing_enrolled:    :benefit_coverage_renewal_open_enrollment_ended,
# benefit_coverage_renewal_application_reverted
          active: :benefit_coverage_period_begin,
          suspended:  :benefit_coverage_period_suspended,
          terminated: :benefit_coverage_period_terminated,
          expired:    :benefit_coverage_period_expired,
        }
    }


  def publish_friendly_event(resource_name, current_state, from_state, to_state, event_payload)
  end

end
