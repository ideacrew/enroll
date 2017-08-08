module PdfTemplates
  class ConditionalEligibilityNotice
    include Virtus.model

    attribute :mpi_indicator, String
    attribute :notification_type, String
    attribute :primary_firstname, String
    attribute :primary_fullname, String
    attribute :primary_identifier, String
    attribute :request_full_determination, Boolean, :default => false
    attribute :is_family_totally_ineligibile, Boolean, :default => false
    attribute :has_applied_for_assistance, Boolean, :default => false
    attribute :notice_date, Date
    attribute :hbe, PdfTemplates::Hbe
    attribute :ivl_open_enrollment_start_on, Date
    attribute :ivl_open_enrollment_end_on, Date
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :enrollments, Array[PdfTemplates::Enrollment]
    attribute :individuals, Array[PdfTemplates::Individual]
    attribute :ssa_unverified, Array[PdfTemplates::Individual]
    attribute :dhs_unverified, Array[PdfTemplates::Individual]
    attribute :residency_inconsistency, Array[PdfTemplates::Individual]
    attribute :income_unverified, Array[PdfTemplates::Individual]
    attribute :indian_inconsistency, Array[PdfTemplates::Individual]
    attribute :mec_conflict, Array[PdfTemplates::Individual]
    attribute :tax_households, Array[PdfTemplates::TaxHousehold]
    attribute :first_name, String
    attribute :last_name, String
    attribute :due_date, Date
    attribute :documents_needed, Boolean
    attribute :eligibility_determinations, Array[PdfTemplates::EligibilityDetermination]
    attribute :coverage_year, String

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

    def current_health_enrollments
      enrollments.select{|enrollment| enrollment.plan.coverage_kind == "health" && enrollment.effective_on.year == TimeKeeper.date_of_record.year}
    end

    def assisted_enrollments
      current_health_enrollments.select{|enrollment| enrollment.is_receiving_assistance == true}
    end

    def csr_enrollments
      current_health_enrollments.select{|enrollment| enrollment.plan.is_csr ==  true}
    end

    def current_dental_enrollments
      enrollments.select{|enrollment| enrollment.plan.coverage_kind == "dental" && enrollment.effective_on.year == TimeKeeper.date_of_record.year}
    end

    def renewal_health_enrollment
      enrollments.detect{|enrollment| enrollment.plan.coverage_kind == "health" && enrollment.effective_on.year == TimeKeeper.date_of_record.next_year.year}
    end

    def renewal_dental_enrollment
      enrollments.detect{|enrollment| enrollment.plan.coverage_kind == "dental" && enrollment.effective_on.year == TimeKeeper.date_of_record.next_year.year}
    end

    def magi_medicaid_eligible
      individuals.select{ |individual| individual.is_medicaid_chip_eligible == true }
    end

    def aqhp_individuals
      individuals.select{ |individual| individual.is_ia_eligible == true  }
    end

    def uqhp_individuals
      individuals.select{ |individual| individual.is_without_assistance == true  }
    end

    def ineligible_applicants
      individuals.select{ |individual| individual.is_totally_ineligible == true  }
    end

    def non_magi_medicaid_eligible
      individuals.select{ |individual| individual.is_non_magi_medicaid_eligible == true  }
    end

    def aqhp_enrollments
      enrollments.select{ |enrollment| enrollment.is_receiving_assistance == true}
    end

    #FIX ME
    def tax_hh_with_csr
      tax_households.select { |thh| thh.csr_percent_as_integer != 100}
    end

    def enrollment_notice_subject
      if current_health_enrollments.present? && assisted_enrollments.present?
        if current_dental_enrollments.present?
          subject = "Your Health Plan, Cost Savings, and Dental Plan"
        else
          subject = "Your Health Plan and Cost Savings"
        end
      elsif current_health_enrollments.present? && assisted_enrollments.nil?
        if current_dental_enrollments.present?
          subject = "Your Health and Dental Plan"
        else
          subject = "Your Health Plan"
        end
      else
        subject = "Your Dental Plan"
      end
    end

    def csr_eligibility_notice_text(csr_percent_as_integer)
      #FIX ME when CSR = NAL
      text = ["<strong>Cost-sharing reductions:</strong> Those listed are also eligible to pay less when getting medical services."]
      case csr_percent_as_integer
      when 73
        text << "For example, an annual deductible that would normally be $2,000 for an individual might be reduced to $1,300. The deductible is how much you must pay for some covered services you use before your insurance company begins to help with costs. <strong>To get these savings, you must select a silver plan.</strong>"
      when 87
        text << "For example, an annual deductible that would normally be $2,000 for an individual might be reduced to $0, and the cost to see an in-network doctor might be $15 instead of $25. The deductible is how much you must pay for some covered services you use before your insurance company begins to help with costs. <strong>To get these savings, you must select a silver plan.</strong>"
      when 94
        text << "For example, an annual deductible that would normally be $2,000 for an individual might be reduced to $0, and the cost to see an in-network doctor might be $0 instead of $25. The deductible is how much you must pay for some covered services you use before your insurance company begins to help with costs. <strong>To get these savings, you must select a silver plan.</strong>"
      when 100
        text << "You won’t pay anything for services you get from providers who are in your plan’s network. You also won’t pay anything for services you receive from an Indian Health Service provider."
      else
        text << "You won’t pay anything for services you receive from an Indian Health Service provider."
      end
    end

    def household_information(ivl)
      rows = []
      household_block = []
      household_block << "<strong>Household Member:</strong>"
      household_block << "#{ivl.full_name} &nbsp;&nbsp;&nbsp;&nbsp; Age: #{ivl.age}"
      rows << household_block
      medicaid_block = []
      medicaid_block << "<strong>Medicaid</strong>"
      block = []
      flag = false
      if ivl.is_medicaid_chip_eligible
        flag = true
        block << "#{ivl.first_name} likely qualifies for Medicaid. Your monthly household income of $#{ivl.tax_household.aptc_csr_annual_household_income} is within the monthly income limit of $#{ivl.magi_medicaid_monthly_income_limit} for this person.  Medicaid offers free, comprehensive health coverage."
      end
      if ivl.is_non_magi_medicaid_eligible
        flag = true
        block << "#{ivl.first_name} may qualify for a special category of Medicaid because you told us on your application that at least one or more of the following apply to #{ivl.first_name}: over age 64; blind or has a disability; applying for long term care, community care, nursing care or other similar services; enrolled in Medicare; formerly in foster care in the District; or receives supplemental security income. Medicaid offers free, comprehensive health coverage."
        block << "Medicaid offers some additional health services to people who qualify in this category. You may be required to submit additional documents."
        block << "The DC Department of Human Services (DHS) will make a final decision on #{ivl.first_name}’s Medicaid eligibility. We have forwarded your application to them."
        block << "IF DHS determines that #{ivl.first_name} qualifies for Medicaid, DHS will provide information on how to enroll."
      end
      if (ivl.is_medicaid_chip_eligible || ivl.is_non_magi_medicaid_eligible) && !(ivl.is_totally_ineligible)
        flag = true
        if ivl.immigration_unverified == true
          block << " #{ivl.first_name} likely doesn’t qualify for Medicaid. Either the person’s immigration status doesn’t meet requirements, or the person has not held the status long enough to qualify for Medicaid."
        else
          block << " #{ivl.first_name} likely doesn’t qualify for Medicaid. Your monthly household income of $#{ivl.tax_household.aptc_csr_annual_household_income} is over the monthly income limit of $#{ivl.magi_medicaid_monthly_income_limit} for this person."
        end
      end

      medicaid_block << block if flag == true
      rows << medicaid_block if medicaid_block.count > 1

      private_health_block = []
      private_health_block << "<strong>Private Health Insurance</strong>"
      block = []
      flag = false
      if (ivl.is_medicaid_chip_eligible || ivl.is_non_magi_medicaid_eligible) && !(ivl.is_totally_ineligible)
        flag = true
        block << "#{ivl.first_name} qualifies to purchase private health insurance through #{Settings.site.short_name}. People who likely qualify for Medicaid also have the option to purchase private health insurance at full price, even though Medicaid offers free, comprehensive health coverage."
      end
      private_health_block << block if flag == true
      rows << private_health_block if private_health_block.count > 1

      aptc_block = []
      aptc_block << "<strong>Advance Premium Tax Credit (APTC)</strong>"
      block = []
      flag = false 
      if ivl.tax_household.max_aptc > 0
        flag = true
        block << "#{ivl.first_name} qualifies for an advance premium tax credit to help pay for the insurance. Your annual household income of $#{ivl.tax_household.aptc_csr_annual_household_income} is within the income limit of $#{ivl.tax_household.aptc_annual_income_limit} for this person. The value of the tax credit is based on your household size, income, and the cost of health plans available to those who qualify."
      end
      if ivl.no_aptc_because_of_income
        flag = true
        block << "#{ivl.first_name} does not qualify for an advance premium tax credit to help pay for the insurance. Your annual household income of $#{ivl.tax_household.aptc_csr_annual_household_income} is over the income limit of $#{ivl.tax_household.aptc_annual_income_limit} for this person."
      end
      if ivl.is_medicaid_chip_eligible
        flag = true
        block << "#{ivl.first_name} does not qualify for an advance premium tax credit to help pay for private health insurance because this person is likely eligible for Medicaid."
      end
      if ivl.no_aptc_because_of_tax
        flag = true
        block << "#{ivl.first_name} does not qualify for an advance premium tax credit to help pay for the insurance for one of the following reasons:"
        block << "Not filing taxes for #{coverage_year}
        Filed taxes separately from spouse for #{coverage_year}
        Someone in the household did not reconcile the tax credit received in a previous year on their federal tax return"
        block << "Call #{Settings.site.short_name} at (855) 532-5465 to find out if this issue can be resolved. If it can, #{Settings.site.short_name} can check again to see if #{ivl.first_name} would be eligible."
      end
      if ivl.has_access_to_affordable_coverage
        flag = true
        block << "#{ivl.first_name} does not qualify for an advance premium tax credit to help pay for the insurance because this person has access to what the federal government considers affordable coverage. "
      end
      aptc_block << block if flag == true
      rows << aptc_block if aptc_block.count > 1

      csr_block = []
      csr_block << "<strong>Cost-Sharing Reductions (CSR)</strong>"
      block = []
      flag = false
      #check CSR condition
      if (ivl.indian_conflict && ivl.tax_household.csr_percent_as_integer != 100)
        flag = true
        block << "#{ivl.first_name} qualifies for cost-sharing reductions, but must select a silver plan to receive them. Your annual household income of $#{ivl.tax_household.aptc_csr_annual_household_income} is within the income limit of $#{ivl.tax_household.csr_annual_income_limit}. With a silver plan, #{ivl.first_name} will get a discount on out-of-pocket costs for medical services."
      end
      if ivl.indian_conflict == true
        flag = true

        if ivl.magi_as_percentage_of_fpl <= 300
          block << "#{ivl.first_name} qualifies for plans with no cost sharing. Your annual household income of $#{ivl.tax_household.aptc_csr_annual_household_income} is within the income limit of $#{ivl.tax_household.csr_annual_income_limit}, and you indicated that #{ivl.first_name} is a member of a federally recognized tribe. This means services covered by a health plan’s network, such as doctor visits, medicines, or emergency care won’t cost anything. Services provided by an Indian Health Service facility are also free."
        elsif ivl.magi_as_percentage_of_fpl > 300
          block << "#{ivl.first_name} qualifies for limited cost-sharing. You indicated that #{ivl.first_name} is a member of a federally recognized tribe. This means #{ivl.first_name} won’t have to pay for services covered by a health plan’s network, such as doctor visits, medicines, or emergency care if this person gets care through the Indian Health Service, Tribal Health Providers, or Urban Indian Health Providers (I/T/U). This person must have a referral from an I/T/U provider to receive covered services from another in-network service provider at no cost."
        end
      end
      if ivl.no_csr_because_of_income
        flag = true
        block << "#{ivl.first_name} does not qualify for cost-sharing reductions because your annual household income of $#{ivl.tax_household.aptc_csr_annual_household_income} is over the income limit of $#{ivl.tax_household.csr_annual_income_limit}."
      end
      if ivl.is_medicaid_chip_eligible
        flag = true
        block << "#{ivl.first_name} does not qualify for cost-sharing reductions because this person is likely eligible for Medicaid."
      end
      if ivl.no_csr_because_of_tax
        flag = true
        block << "#{ivl.first_name} does not qualify for cost-sharing reductions for one of the following reasons:
          Not filing taxes for #{coverage_year}
          Filed taxes separately from spouse for #{coverage_year}
          Did not reconcile the tax credit received in a previous year on this person’s federal tax return
          Call #{Settings.site.short_name} at (855) 532-5465 to find out if this issue can be resolved. If it can, #{Settings.site.short_name} can check again to see if #{ivl.first_name} would be eligible."
      end
      if ivl.tax_household.csr_percent_as_integer.nil? && ivl.has_access_to_affordable_coverage
        flag = true
        block << "#{ivl.first_name} does not qualify for cost-sharing reductions because this person has access to what the federal government considers affordable coverage."
      end
      csr_block << block if flag == true
      rows << csr_block if csr_block.count > 1

      ineligible_for_medicaid = []
      ineligible_for_medicaid << "<strong>Ineligible for Medicaid and Private Health Insurance</strong>"
      block = []
      flag = false
      if ivl.is_totally_ineligible
        flag = true
        block << "#{ivl.first_name} does not qualify for Medicaid or private health insurance (with or without help paying for coverage). The reason is because #{ivl.reason_for_ineligibility.join(' In addition, ')} If #{ivl.first_name}’s status changes, we encourage you to update your application, or call #{Settings.site.short_name} at #{hbe.phone}."
      end
      ineligible_for_medicaid << block if flag == true
      rows << ineligible_for_medicaid if ineligible_for_medicaid.count > 1
      rows
    end
  end
end