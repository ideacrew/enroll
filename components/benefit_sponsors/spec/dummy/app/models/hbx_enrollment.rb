require 'ostruct'

class HbxEnrollment
  include Mongoid::Document

  include Mongoid::Timestamps


  embedded_in :household

  ENROLLMENT_KINDS    = %w(open_enrollment special_enrollment)
  COVERAGE_KINDS      = %w(health dental)

  ENROLLED_STATUSES   = %w(coverage_selected transmitted_to_carrier coverage_enrolled coverage_termination_pending
                              enrolled_contingent unverified
                            )
  SELECTED_AND_WAIVED = %w(coverage_selected inactive)
  TERMINATED_STATUSES = %w(coverage_terminated unverified coverage_expired void)
  CANCELED_STATUSES   = %w(coverage_canceled)
  RENEWAL_STATUSES    = %w(auto_renewing renewing_coverage_selected renewing_transmitted_to_carrier renewing_coverage_enrolled
                              auto_renewing_contingent renewing_contingent_selected renewing_contingent_transmitted_to_carrier
                              renewing_contingent_enrolled
                            )
  WAIVED_STATUSES     = %w(inactive renewing_waived)

end
