module Queries
  class ShopMonthlyEnrollments
    include QueryHelpers

    def initialize
      @pipeline = []
    end

    def add(step)
      @pipeline << step.to_hash
    end

    def evaluate
      Family.collection.aggregate(@pipeline)
    end

    def filter_families_by_employers(feins, effective_on)
      find_benefit_group_ids(feins, effective_on)
    
      add({
        "$match" => { 
          "households.hbx_enrollments.benefit_group_id" => {"$in" => @bg_ids_list}
        }
      })

      self
    end

    def unwind_enrollments
      add({"$unwind" => "$households"})
      add({"$unwind" => "$households.hbx_enrollments"})
      self
    end

    def filter_enrollments_by_status
      add({
        "$match" => {
          "households.hbx_enrollments.aasm_state" => {
            "$in" => HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES
          }
        }
      })
      self
    end

    def filter_enrollments_by_employer(feins, effective_on)
      find_benefit_group_ids(feins, effective_on)

      add({
        "$match" => {
          "households.hbx_enrollments.benefit_group_id" => {"$in" => @bg_ids_list},
          "households.hbx_enrollments.effective_on" => effective_on          
        }
      })
      self
    end

    def filter_by_open_enrollment
      add({
        "$match" => {
          "households.hbx_enrollments.enrollment_kind" => "open_enrollment"
        }
      })
      self
    end

    def sort_by_submitted_at
      add({
       "$sort" => {"households.hbx_enrollments.submitted_at" => 1}
       })
      self
    end

    def group_by_coverage_kind_and_assignment
      add({
        "$group" => {
          "_id" => {
            "bga_id" => "$households.hbx_enrollments.benefit_group_assignment_id",
            "coverage_kind" => "$households.hbx_enrollments.coverage_kind"
          },
          "hbx_enrollment_id" => { "$last" => "$households.hbx_enrollments.hbx_id" }
        }
      })

      self
    end

    def project_enrollment_ids
      add({
        "$project" => {
         "_id" => 0,
         "enrollment_hbx_id" => "$hbx_enrollment_id"
        }
      })
      self
    end

    def find_benefit_group_ids(feins, effective_on)
      return @bg_ids_list if defined? @bg_ids_list
      formatted_feins = feins.collect{|e| prepend_zeros(e.to_s, 9) }

      employers = formatted_feins.collect{|fein| EmployerProfile.find_by_fein(fein)}.compact
      @bg_ids_list = employers.inject([]) do |id_list, employer|
        plan_year = employer.plan_years.published_or_renewing_published.where(:start_on => effective_on).first
        if plan_year.present?
          id_list += plan_year.benefit_groups.map(&:id)
        else
          id_list
        end
      end
    end

    def prepend_zeros(number, n)
      (n - number.to_s.size).times { number.prepend('0') }
      number
    end
  end
end