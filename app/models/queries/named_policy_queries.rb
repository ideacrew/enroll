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
      result = employer_shop_coverages(feins, effective_on)
      result.select{|r| r['_id']["effective_on"] == effective_on}.collect{|r| r['enrollment_hbx_id']}
    end

    def self.shop_monthly_terminations(feins, effective_on)
      result = employer_shop_coverages(feins, effective_on)
      result.group_by{|r| r["_id"]["subscriber"]}.inject([]) do |termed_enrollments, (subscriber, records)|
        prev_enrollments = records.select{|r| r["_id"]["effective_on"] < effective_on}

        termed_enrollments += prev_enrollments.select do |prev_e|
          records.none? do |r|
            prev_e["_id"]["employee_role_id"] == r["_id"]["employee_role_id"] && 
            prev_e["_id"]["coverage_kind"] == r["_id"]["coverage_kind"] &&
            r["_id"]["effective_on"] == effective_on 
          end
        end.collect{|record| record['enrollment_hbx_id']}
      end
    end

    def self.employer_shop_coverages(feins, effective_on)
      qs = ::Queries::ShopMonthlyEnrollments.new(feins, effective_on)
      qs.query_families
        .unwind_enrollments
        .query_enrollments
        .unwind_enrollment_members
        .project_enrollments_with_subscriber
        .filter_missing_subscribers
        .sort("submitted_at")
        .group_enrollments
        .project_enrollment_ids

      qs.evaluate
    end
  end
end
