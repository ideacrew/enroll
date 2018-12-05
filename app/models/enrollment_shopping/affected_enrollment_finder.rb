module EnrollmentShopping
  # Find enrollments that are or have the potential to be affected by a
  # purchase.
  class AffectedEnrollmentFinder
    def for_sponsored_benefit_and_date(enrollment, sponsored_benefit, coverage_date)
      family = enrollment.family
      family.active_household.hbx_enrollments.show_enrollments_sans_canceled.select do |hbx_enrollment|
        (hbx_enrollment.sponsored_benefit_id == sponsored_benefit.id) && hbx_enrollment.active_during?(coverage_date) &&
          (hbx_enrollment.id != enrollment.id) && (hbx_enrollment.coverage_kind == enrollment.coverage_kind)
      end
    end
  end
end
