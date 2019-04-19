module Notifier
  class MergeDataModels::CensusEmployee
    include Virtus.model
   
    attribute :latest_terminated_health_enrollment_plan_name, String
    attribute :latest_terminated_health_enrollment_enrolled_count, String
    attribute :latest_terminated_health_enrollment_coverage_end_on, String

    attribute :latest_terminated_dental_enrollment_plan_name, String
    attribute :latest_terminated_dental_enrollment_enrolled_count, String
    attribute :latest_terminated_dental_enrollment_coverage_end_on, String

    def self.stubbed_object
      notice = Notifier::MergeDataModels::CensusEmployee.new
      notice.latest_terminated_health_enrollment_plan_name = "Aetna Health Plan "
      notice.latest_terminated_health_enrollment_enrolled_count = "Aetna Health Plan "
      notice.latest_terminated_health_enrollment_coverage_end_on = "CareFirst Dental Plan"
      
      notice.latest_terminated_dental_enrollment_plan_name = "CareFirst Dental Plan"
      notice.latest_terminated_dental_enrollment_enrolled_count = "Aetna Health Plan "
      notice.latest_terminated_dental_enrollment_coverage_end_on = "CareFirst Dental Plan"
      notice
    end
  end
end