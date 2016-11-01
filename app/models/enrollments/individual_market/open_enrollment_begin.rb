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
      @logger = Logger.new("#{Rails.root}/log/ivl_open_enrollment_begin_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
    end
     
    def query_criteria
      {
        :kind => 'individual',
        :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES - ["coverage_renewed", "coverage_termination_pending"],
        :coverage_kind.in => HbxEnrollment::COVERAGE_KINDS
        # :effective_on.gte => HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.start_on
      }
    end

    def families
      Family.where(:"households.hbx_enrollments" => {:$elemMatch => query_criteria})
    end

    def has_catastrophic_plan?(enrollment)
      enrollment.plan.metal_level == 'catastrophic'       
    end

    def is_individual_assisted?(enrollment)
      enrollment.applied_aptc_amount > 0 || enrollment.elected_premium_credit > 0 || enrollment.applied_premium_credit > 0 || is_csr?(enrollment)
    end

    def is_csr?(enrollment)
      csr_plan_variants = EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP.except('csr_100').values
      (enrollment.plan.metal_level == "silver") && (csr_plan_variants.include?(enrollment.plan.csr_variant_id))
    end

    def process

      count = 0
      families.each do |family|
          # begin
            enrollments = family.active_household.hbx_enrollments.where(query_criteria).order(:"effective_on".desc)
            enrollments = enrollments.select{|en| HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.contains?(en.effective_on)}
            # hbxe = enrollments.reduce([]) { |list, en| list << en if HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.contains?(en.effective_on)}

            enrollments.each do |enrollment|
              next if has_catastrophic_plan?(enrollment) || is_individual_assisted?(enrollment)

              puts "#{enrollment.hbx_id}--#{enrollment.kind}--#{enrollment.aasm_state}--#{enrollment.coverage_kind}--#{enrollment.effective_on}--#{enrollment.plan.renewal_plan.try(:active_year)}"
              count += 1

              if count % 100 == 0
                puts "Found #{count} enrollments"
              end

              if count % 25 == 0
                puts "--processing--#{enrollment.hbx_id}"
              end

              enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
              enrollment_renewal.enrollment = enrollment
              enrollment_renewal.renew
            end
          # rescue Exception => e 
          #   @logger.info "Failed #{family.e_case_id} Exception: #{e.inspect}"
          # end
      end
      puts count
    end

    # valid_enrollments = enrollments_for_renewal(enrollments)
    # def enrollments_for_renewal(enrollments)
    #   # Multiple or Single of Same coverage kind
    #   enrollments
    #   # matched_enrollments = []
    #   # enrollments_to_renew = []

    #   # while (enrollments - matched_enrollments).any? do
    #   #   enrollment, matched_enrollments = filter_exact_matches((enrollments - matched_enrollments))
    #   #   enrollments_to_renew << enrollment
    #   # end
    #   # enrollments_to_renew
    # end

    # def find_exact_matches(enrollments)
    #   enrollment = enrollments.first
    #   enrollment_hbx_ids = enrollment.hbx_enrollment_members.map(&:hbx_id)

    #   enrollments.reject! do |en|
    #     en_hbx_ids = en.hbx_enrollment_members.map(&:hbx_id)
    #     en_hbx_ids.any?{|z| !enrollment_hbx_ids.include?(z)} || enrollment_hbx_ids.any?{|z| !en_hbx_ids.include?(z)}
    #   end

    #   enrollment <=> 

    #   # enrollments.reject!{|en| (en.plan_id != enrollment.plan_id)}
    #   # enrollments.reject!{|en| (en.effective_on != enrollment.effective_on)}
    #   enrollments

    #   [enrollment, enrollments]
    # end
  # end
end
