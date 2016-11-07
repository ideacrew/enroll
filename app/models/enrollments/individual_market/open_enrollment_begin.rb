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
        :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES - ["coverage_renewed", "coverage_termination_pending"]),
        :coverage_kind.in => HbxEnrollment::COVERAGE_KINDS
        # :effective_on.gte => HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.start_on
      }
    end

    def families
      Family.where(:"households.hbx_enrollments" => {:$elemMatch => query_criteria})
    end

  
    def is_individual_assisted?(enrollment)
      enrollment.applied_aptc_amount > 0 || enrollment.elected_premium_credit > 0 || enrollment.applied_premium_credit > 0 || is_csr?(enrollment)
    end

    def is_csr?(enrollment)
      csr_plan_variants = EligibilityDetermination::CSR_KIND_TO_PLAN_VARIANT_MAP.except('csr_100').values
      (enrollment.plan.metal_level == "silver") && (csr_plan_variants.include?(enrollment.plan.csr_variant_id))
    end

    def process

      current_benefit_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
      renewal_benefit_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period

      count = 0
      families.each do |family|
          begin
            enrollments = family.active_household.hbx_enrollments.where(query_criteria).order(:"effective_on".desc)
            enrollments = enrollments.select{|en| current_benefit_coverage_period.contains?(en.effective_on)}
            # hbxe = enrollments.reduce([]) { |list, en| list << en if HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period.contains?(en.effective_on)}

            enrollments.each do |enrollment|
              next if is_individual_assisted?(enrollment)

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
              enrollment_renewal.renewal_benefit_coverage_period = renewal_benefit_coverage_period
              enrollment_renewal.renew
            end
          rescue Exception => e 
            @logger.info "Failed #{family.e_case_id} Exception: #{e.inspect}"
          end
      end
      puts count
    end


    def process_enrollment_renewal(enrollment, renewal_benefit_coverage_period)
      puts "#{enrollment.hbx_id}--#{enrollment.kind}--#{enrollment.aasm_state}--#{enrollment.coverage_kind}--#{enrollment.effective_on}--#{enrollment.plan.renewal_plan.try(:active_year)}"

      enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
      enrollment_renewal.enrollment = enrollment
      enrollment_renewal.renewal_benefit_coverage_period = renewal_benefit_coverage_period
      enrollment_renewal.renew
    end

    def process_from_sheet
      count = 0

      CSV.open("#{Rails.root}/IVL_Enrollment_Renewals.csv", "w") do |csv|

        csv << ["Enrollment HBX ID", "Subscriber HBX ID", "SSN", "Last Name", "First Name", "HIOS_ID:PlanName", "Other Effective On",  
          "Effective On",  "AASM State",  "Terminated On Action",  "Section:Attribute"]

        renewal_benefit_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period

        CSV.foreach("#{Rails.root}/PositiveMatchesToBeRenewed-1101.csv", headers: true, :encoding => 'utf-8') do |row|
          count += 1

          if count % 100 == 0
            puts "Found #{count} enrollments"
          end

          hbx_enrollment = HbxEnrollment.by_hbx_id(row.to_hash["Enrollment HBX ID"]).first

          status = if hbx_enrollment.blank?
            count += 1
            ["Renewal Failed: Unable to find matching enrollment."]
          elsif !HbxEnrollment::ENROLLED_STATUSES.include?(hbx_enrollment.aasm_state.to_s)
            ["Renewal Failed: Enrollment in #{hbx_enrollment.aasm_state} state."]
          elsif has_catastrophic_plan?(hbx_enrollment)
            ["Renewal Failed: Catastrophic plan found."]
          elsif is_individual_assisted?(hbx_enrollment)
            ["Renewal Failed: Assisted Enrollment."]
          else
            begin
              process_enrollment_renewal(hbx_enrollment, renewal_benefit_coverage_period)
              ["Renewal Successful."]
            rescue Exception => e
              ["Renewal Failed: #{e.tos}."]
            end
          end

          csv << (row.to_h.values + status)
        end

        puts count
      end
    end
end
