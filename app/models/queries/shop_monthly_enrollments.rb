module Queries
  class ShopMonthlyEnrollments

    def initialize(feins = [])
      @feins = feins
    end

    def find
      @feins.inject({}) do |enrollments_under_employers, fein|
        employer_profile = EmployerProfile.find_by_fein(fein)
        if employer_profile.present?
          plan_year = employer_profile.plan_years.published_or_renewing_published.order_by("start_on DESC").first
          if plan_year.present?
            enrollments_under_employers[fein] = enrollment_hbx_ids(plan_year)
          end
        end
        enrollments_under_employers
      end
    end

    def enrollment_hbx_ids(plan_year)
      id_list = plan_year.benefit_groups.map(&:id)

      Family.collection.aggregate([
        {"$match" => { 
          "households.hbx_enrollments" => { "$elemMatch" => {
            "benefit_group_id" => {"$in" => id_list},
            "aasm_state" => {"$in" => valid_enrollment_statuses},
            "effective_on" => plan_year.start_on,
            "enrollment_kind" => "open_enrollment"
        }}}},
        {"$unwind" => "$households"},
        {"$unwind" => "$households.hbx_enrollments"},
        {"$match" => {
          "households.hbx_enrollments.benefit_group_id" => {"$in" => id_list},
          "households.hbx_enrollments.aasm_state" => {"$in" => valid_enrollment_statuses},
          "households.hbx_enrollments.effective_on" => plan_year.start_on,
          "households.hbx_enrollments.enrollment_kind" => "open_enrollment"
        }},
        {"$sort" => {"households.hbx_enrollments.submitted_at" => 1}},
        group_query,
        project_query
      ]).collect{|record| record['enrollment_hbx_id']}
    end

    def group_query
      {
        "$group" => {
          "_id" => {
            "bga_id" => "$households.hbx_enrollments.benefit_group_assignment_id",
            "coverage_kind" => "$households.hbx_enrollments.coverage_kind"
          },
          "hbx_enrollment_id" => { "$last" => "$households.hbx_enrollments.hbx_id" }
        }
      }
    end

    def project_query
      {
        "$project" => {
         "_id" => 0,
         "enrollment_hbx_id" => "$hbx_enrollment_id"
        }
      }
    end
    
    def valid_enrollment_statuses
      HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES
    end
  end
end