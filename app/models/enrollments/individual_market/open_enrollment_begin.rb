class Enrollments::IndividualMarket::OpenEnrollmentBegin
   

    # Active IVL hbx enrollments
    # without a termination date in the current year
    # kind 'individual'
    # health || dental
    # effective on >= 1/1/2016
    # terminated_on.blank? || terminated_on > 12/31/2016
    # hbx sponsored benefit
    # Unassisted, Assisted, CSR Assisted, Catastrophic
    # Responsible party
    # :$or => [
    #   :terminated_on.lte => HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.end_on,
    #   :terminated_on => nil
    # ]
    # TODO: Move aged off people from immedidate coverage household to extended coverage household on the day new benefit coverage period begin.

    def initialize
    end
     
    def query_criteria
      {
        :kind => 'individual',
        :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES,
        :effective_on.gte => HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.start_on
      }
    end

    def families
      Family.where(:"households.hbx_enrollments" => {:$elemMatch => query_criteria})
    end

    def process
      families.each do |family|
        HbxEnrollment::COVERAGE_KINDS.each do |coverage_kind|
          enrollments = family.active_household.hbx_enrollments.where(query_criteria).order(:"effective_on".desc)
          valid_enrollments = enrollments_for_renewal(enrollments)
          valid_enrollments.each do |enrollment|
            enrollment_renewal = FamilyEnrollmentRenewal.new
            enrollment_renewal.enrollment = enrollment
            enrollment_renewal.renew
          end
        end
      end
    end

    def enrollments_for_renewal(enrollments)
      matched_enrollments = []
      enrollments_to_renew = []

      while (enrollments - matched_enrollments).any? do
        enrollment, matched_enrollments = filter_exact_matches((enrollments - matched_enrollments))
        enrollments_to_renew << enrollment
      end

      enrollments_to_renew
    end

    def find_exact_matches(enrollments)
      enrollment = enrollments.first
      enrollment_hbx_ids = enrollment.hbx_enrollment_members.map(&:hbx_id)

      enrollments.reject! do |en|
        en_hbx_ids = en.hbx_enrollment_members.map(&:hbx_id)
        en_hbx_ids.any?{|z| !enrollment_hbx_ids.include?(z)} || enrollment_hbx_ids.any?{|z| !en_hbx_ids.include?(z)}
      end

      enrollments.reject!{|en| (en.plan_id != enrollment.plan_id)}
      enrollments.reject!{|en| (en.effective_on != enrollment.effective_on)}
      enrollments

      [enrollment, enrollments]
    end
  end
end
