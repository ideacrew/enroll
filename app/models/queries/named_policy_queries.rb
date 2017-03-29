module Queries
  class NamedPolicyQueries
    def self.all_outstanding_shop
      qs = ::Queries::PolicyAggregationPipeline.new
      qs.filter_to_shop.filter_to_active.with_effective_date({"$gt" => Date.new(2015,1,31)}).eliminate_family_duplicates
      enroll_pol_ids = []
      qs.evaluate.each do |r|
        enroll_pol_ids << r['hbx_id']
      end
      enroll_pol_ids
    end

    def self.shop_monthly_enrollments(feins, effective_on)
      qs = ::Queries::ShopMonthlyEnrollments.new

      qs.filter_families_by_employers(feins, effective_on)
        .unwind_enrollments
        .filter_enrollments_by_employer(feins, effective_on)
        .filter_enrollments_by_status
        .filter_by_open_enrollment
        .sort_enrollments
        .group_them_by_kind
        .project_enrollment_ids

      qs.evaluate.collect{|record| record['enrollment_hbx_id']}
    end
  end
end
