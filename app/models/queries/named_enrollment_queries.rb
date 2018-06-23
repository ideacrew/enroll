module Queries
  class NamedEnrollmentQueries

    def self.shop_initial_enrollments(organization, effective_on)
      benefit_package_ids = find_ie_benefit_package_ids(organization, effective_on)

      Family.collection.aggregate([
        {
          "$match" => {
            "households.hbx_enrollments.sponsored_benefit_package_id" => {"$in" => benefit_package_ids}
          }
        },
        {"$unwind" => "$households"},
        {"$unwind" => "$households.hbx_enrollments"},
        { "$match" => {
          "households.hbx_enrollments.sponsored_benefit_package_id" => {"$in" => benefit_package_ids},
          "households.hbx_enrollments.aasm_state" => {"$in" => new_enrollment_statuses},
          "households.hbx_enrollments.effective_on" => effective_on,
          "households.hbx_enrollments.kind" => {"$in" => ["employer_sponsored", "employer_sponsored_cobra"]}
        }},
        {"$sort" => {"households.hbx_enrollments.submitted_at" => 1}},
        {
           "$group" => {
             "_id" => {
               "employee_role_id" => "$households.hbx_enrollments.employee_role_id",
               "sponsored_benefit_id" => "$households.sponsored_benefit_id"
             },
            "hbx_enrollment_id" => {"$last" => "$households.hbx_enrollments.hbx_id"},
            "submitted_at" => {"$last" => "$households.hbx_enrollments.submitted_at"}
           }
        }
      ]).lazy.map do |rec|
        rec["hbx_enrollment_id"]
      end
    end

    def self.find_ie_benefit_package_ids(organization, effective_on)
      benefit_sponsorships = ::BenefitSponsors::BenefitSponsorships::BenefitSponsorship.by_profile(organization.employer_profile).may_transmit_initial_enrollment?(effective_on)

      benefit_sponsorships.flat_map do |bs|
        bs.benefit_applications.select do |ba|
          (ba.start_on == effective_on) && ["active", "enrollment_eligible"].include?(ba.aasm_state.to_s)
        end
      end.flat_map do |b_app|
        b_app.benefit_packages.map(&:id)
      end
    end

    def self.new_enrollment_statuses
      HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::TERMINATED_STATUSES
    end
=begin
    def self.all_outstanding_shop
      qs = ::Queries::PolicyAggregationPipeline.new
      qs.filter_to_shop.filter_to_active.with_effective_date({"$gt" => Date.new(2015,1,31)}).eliminate_family_duplicates
      enroll_pol_ids = []
      qs.evaluate.each do |r|
        enroll_pol_ids << r['hbx_id']
      end
      enroll_pol_ids
    end

    def self.can_be_skipped?(hbx_id)
      enrollment = HbxEnrollment.by_hbx_id(hbx_id)[0]
      plan_year = enrollment.benefit_group.plan_year

      # Skip renewal enrollments that're purchased later than quiet period end date from shop monthly query.
      if plan_year.has_renewal_history?
        enrollment.submitted_at > plan_year.enrollment_quiet_period.end
      else
        plan_year.enrollment_quiet_period.cover?(enrollment.submitted_at)
      end
    end

    def self.shop_quiet_period_enrollments(effective_on, enrollment_statuses)
      feins = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {
        :start_on => effective_on, :aasm_state => 'enrolled'
        }}).pluck(:fein)

      qs = ::Queries::ShopMonthlyEnrollments.new(feins, effective_on)
      qs.enrollment_statuses = enrollment_statuses

      qs.query_families_with_quiet_period_enrollments
        .unwind_enrollments
        .query_quiet_period_enrollments
        .sort_enrollments
        .group_enrollment_events
        .project_enrollment_ids
      qs.evaluate.collect{|r| r['enrollment_hbx_id']}
    end

    def self.shop_monthly_terminations(feins, effective_on)
      qs = ::Queries::ShopMonthlyEnrollments.new(feins, effective_on)
      qs.query_families
        .unwind_enrollments
        .query_enrollments
        .sort_enrollments
        .group_enrollments
        .project_enrollment_ids

      qs.evaluate.group_by{|r| r["_id"]["employee_role_id"]}.inject([]) do |termed_enrollments, (subscriber, records)|
        prev_enrollments = records.select{|r| r["_id"]["effective_on"] < effective_on}

        termed_enrollments += prev_enrollments.select do |prev_e|
          records.none? do |r|
            prev_e["_id"]["coverage_kind"] == r["_id"]["coverage_kind"] && r["_id"]["effective_on"] == effective_on 
          end
        end.collect{|record| record['enrollment_hbx_id']}
      end
    end
=end
  end
end
