module PdfTemplates
  class ConditionalEligibilityNotice
    include Virtus.model

    attribute :mpi_indicator, String
    attribute :notification_type, String
    attribute :primary_fullname, String
    attribute :primary_identifier, String
    attribute :request_full_determination, Boolean, :default => false
    attribute :is_family_totally_ineligibile, Boolean, :default => false
    attribute :has_applied_for_assistance, Boolean, :default => false
    attribute :notice_date, Date
    attribute :ivl_open_enrollment_start_on, Date
    attribute :ivl_open_enrollment_end_on, Date
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :enrollments, Array[PdfTemplates::Enrollment]
    attribute :individuals, Array[PdfTemplates::Individual]
    attribute :ssa_unverified, Array[PdfTemplates::Individual]
    attribute :dhs_unverified, Array[PdfTemplates::Individual]
    attribute :tax_households, Array[PdfTemplates::TaxHousehold]
    attribute :first_name, String
    attribute :last_name, String
    attribute :due_date, String
    attribute :eligibility_determinations, Array[PdfTemplates::EligibilityDetermination]
    attribute :assistance_year, Date

    def other_enrollments
      enrollments.reject{|enrollment| enrollments.index(enrollment).zero? }
    end

    def shop?
      false
    end

    def verified_individuals
      individuals.select{|individual| individual.verified }
    end

    def unverified_individuals
      individuals.reject{|individual| individual.verified }
    end

    def ssn_unverified
      individuals.reject{|individual| individual.ssn_verified}
    end

    def citizenship_unverified
      individuals.reject{|individual| individual.citizenship_verified}
    end

    def residency_unverified
      individuals.reject{|individual| individual.residency_verified}
    end

    def indian_conflict
      individuals.select{|individual| individual.indian_conflict}
    end

    def incarcerated
      individuals.select{|individual| individual.incarcerated}
    end

    def current_health_enrollment
      enrollments.detect{|enrollment| enrollment.plan.coverage_kind == "health" && enrollment.effective_on.year == TimeKeeper.date_of_record.year}
    end

    def current_dental_enrollment
      enrollments.detect{|enrollment| enrollment.plan.coverage_kind == "dental" && enrollment.effective_on.year == TimeKeeper.date_of_record.year}
    end

    def renewal_health_enrollment
      enrollments.detect{|enrollment| enrollment.plan.coverage_kind == "health" && enrollment.effective_on.year == TimeKeeper.date_of_record.next_year.year}
    end

    def renewal_dental_enrollment
      enrollments.detect{|enrollment| enrollment.plan.coverage_kind == "dental" && enrollment.effective_on.year == TimeKeeper.date_of_record.next_year.year}
    end

    def magi_medicaid_eligible
      individuals.select{ |individual| individual[:is_medicaid_chip_eligible] == true }
    end

    def aqhp_individuals
      individuals.select{ |individual| individual[:is_ia_eligible] == true  }
    end

    def uqhp_individuals
      individuals.select{ |individual| individual[:is_without_assistance] == true  }
    end

    def ineligible_applicants
      individuals.select{ |individual| individual[:is_totally_ineligible] == true  }
    end

    def non_magi_medicaid_eligible
      individuals.select{ |individual| individual[:is_non_magi_medicaid_eligible] == true  }
    end

    #FIX ME
    def tax_hh_with_csr
      tax_households.select { |thh| thh[:csr_percent_as_integer] != 100}
    end

    def csr_eligibility_notice_text(csr_percent_as_integer)
      #FIX ME when CSR = NAL
      text = ["<strong>Cost-sharing reductions:</strong> Those listed are also eligible to pay less when getting medical services."]
      case csr_percent_as_integer
      when 73
        text << "For example, an annual deductible that would normally be $2,000 for an individual might be reduced to $1,300. The deductible is how much you must pay for some covered services you use before your insurance company begins to help with costs. <strong>To get these savings, you must select a silver plan.</strong>"
      when 87
        text << "For example, an annual deductible that would normally be $2,000 for an individual might be reduced to $0, and the cost to see an in-network doctor might be $15 instead of $25. The deductible is how much you must pay for some covered services you use before your insurance company begins to help with costs.  <strong>To get these savings, you must select a silver plan.</strong>"
      when 94
        text << "For example, an annual deductible that would normally be $2,000 for an individual might be reduced to $0, and the cost to see an in-network doctor might be $0 instead of $25. The deductible is how much you must pay for some covered services you use before your insurance company begins to help with costs.  <strong>To get these savings, you must select a silver plan.</strong>"
      when 100
        text << "You won’t pay anything for services you get from providers who are in your plan’s network. You also won’t pay anything for services you receive from an Indian Health Service provider."
      else
        text << "You won’t pay anything for services you receive from an Indian Health Service provider."
      end
    end

  end
end