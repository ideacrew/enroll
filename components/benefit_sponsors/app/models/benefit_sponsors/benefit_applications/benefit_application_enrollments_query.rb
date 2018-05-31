module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationEnrollmentsQuery

      attr_reader :benefit_application

      def initialize(benefit_application)
        @benefit_application = benefit_application
      end

      def call(klass_name, date)
        klass_name.collection.aggregate([
          {"$match" => { "households.hbx_enrollments" => {
            "$elemMatch" => {
            "sponsored_benefit_package_id" => {
              "$in" => benefit_package_ids
            },
            "aasm_state" => { "$in" => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES + HbxEnrollment::WAIVED_STATUSES)},
            "effective_on" =>  {"$lte" => date.end_of_month, "$gte" => benefit_application.effective_period.min}
          }}}},
          {"$unwind" => "$households"},
          {"$unwind" => "$households.hbx_enrollments"},
          {"$match" => {
            "households.hbx_enrollments.sponsored_benefit_package_id" => {
              "$in" => benefit_package_ids
            },
            "households.hbx_enrollments.aasm_state" => { "$in" => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES + HbxEnrollment::WAIVED_STATUSES)},
            "households.hbx_enrollments.effective_on" =>  {"$lte" => date.end_of_month, "$gte" => benefit_application.effective_period.min},
            "$or" => [
             {"households.hbx_enrollments.terminated_on" => {"$eq" => nil} },
             {"households.hbx_enrollments.terminated_on" => {"$gte" => date.end_of_month}}
            ]
          }},
          {"$sort" => {
            "households.hbx_enrollments.submitted_at" => 1
          }},
          {"$group" => {
            "_id" => {
              "bga_id" => "$households.hbx_enrollments.benefit_group_assignment_id",
              "coverage_kind" => "$households.hbx_enrollments.coverage_kind"
            },
            "hbx_enrollment_id" => {"$last" => "$households.hbx_enrollments._id"},
            "aasm_state" => {"$last" => "$households.hbx_enrollments.aasm_state"},
            "plan_id" => {"$last" => "$households.hbx_enrollments.plan_id"},
            "benefit_group_id" => {"$last" => "$households.hbx_enrollments.benefit_group_id"},
            "benefit_group_assignment_id" => {"$last" => "$households.hbx_enrollments.benefit_group_assignment_id"},
            "family_members" => {"$last" => "$family_members"}
          }},
          {"$match" => {"aasm_state" => {"$nin" => HbxEnrollment::WAIVED_STATUSES}}}
        ])
      end

      def benefit_package_ids
        benefit_application.benefit_packages.collect(&:_id)
      end
    end
  end
end