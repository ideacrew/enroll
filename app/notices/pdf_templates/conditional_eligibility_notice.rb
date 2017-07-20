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

    def aqhp_enrollments
      enrollments.select{ |enrollment| enrollment[:is_receiving_assistance] == true}.present?
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

    def something(ivl)
      rows = []
      household_block = []
      household_block << "Household Member:"
      household_block << "#{ivl[:full_name]} Age: #{ivl[:age]}"
      rows << household_block
      medicaid_block = []
      medicaid_block << "Medicaid"
      block = []
      flag = false
      if ivl[:is_medicaid_chip_eligible] == false
        flag = true
        block << "#{ivl[:first_name]} likely qualifies for Medicaid. Your monthly household income of <$monthly household income> is within the monthly income limit of <$Medicaid monthly income limit 1, 2 or 3 based on age + type of applicant> for this person.  Medicaid offers free, comprehensive health coverage."
      end
      if ivl[:is_non_magi_medicaid_eligible] == false
        flag = true
        block << "#{ivl[:first_name]} may qualify for a special category of Medicaid because you told us on your application that at least one or more of the following apply to <person First Name>: over age 64; blind or has a disability; applying for long term care, community care, nursing care or other similar services; enrolled in Medicare; formerly in foster care in the District; or receives supplemental security income. Medicaid offers free, comprehensive health coverage."
        block << "Medicaid offers some additional health services to people who qualify in this category. You may be required to submit additional documents."
        block <<  "The DC Department of Human Services (DHS) will make a final decision on <Person First Name>’s Medicaid eligibility. We have forwarded your application to them."
        block <<  "IF DHS determines that <Person First Name> qualifies for Medicaid, DHS will provide information on how to enroll."
      end
      if ivl[:is_dummy1] == false
        flag = true
        block << " #{ivl[:first_name]} likely doesn’t qualify for Medicaid. Your monthly household income of <$monthly household income> is over the monthly income limit of <$monthly income limit for Medicaid 1 2 or 3 based on age> for this person."
      end
      if ivl[:is_dummy2] == false
        flag = true
        block << " #{ivl[:first_name]} likely doesn’t qualify for Medicaid. Either the person’s immigration status doesn’t meet requirements, or the person has not held the status long enough to qualify for Medicaid."
      end
      medicaid_block << block if flag == true
      rows << medicaid_block if medicaid_block.count > 1

      private_health_block = []
      private_health_block << "Private Health Insurance"
      block = []
      flag = false
      if ivl[:is_medicaid_chip_eligible] == false
        flag = true
        block << "#{ivl[:first_name]} qualifies to purchase private health insurance through DC Health Link. [If MAGI MEDICAID=YES]People who likely qualify for Medicaid also have the option to purchase private health insurance at full price, even though Medicaid offers free, comprehensive health coverage."
      end
      private_health_block << block if flag == true
      rows << private_health_block if private_health_block.count > 1

      aptc_block = []
      aptc_block << "Advance Premium Tax Credit (APTC)" 
      block = []
      flag = false 
      if ivl[:is_medicaid_chip_eligible] == false
        flag = true
        block << "#{ivl[:first_name]} qualifies for an advance premium tax credit to help pay for the insurance. Your annual household income of <$annual household income> is within the income limit of <$APTC annual income limit> for this person. The value of the tax credit is based on your household size, income, and the cost of health plans available to those who qualify." 
      end
      if ivl[:is_medicaid_chip_eligible] == false
        flag = true
        block << "<Person First Name> does not qualify for an advance premium tax credit to help pay for the insurance. Your annual household income of <$annual household income> is over the income limit of <$APTC annual income limit> for this person." 
      end
      if ivl[:is_medicaid_chip_eligible] == false
        flag = true
        block << "<Person First Name> does not qualify for an advance premium tax credit to help pay for private health insurance because this person is likely eligible for Medicaid" 
      end
      if ivl[:is_medicaid_chip_eligible] == false
        flag = true
        block << "to help pay for the insurance for one of the following reasons:
          Not filing taxes for <coverage year>
          Filed taxes separately from spouse for <coverage year>
          Someone in the household did not reconcile the tax credit received in a previous year on their federal tax return
          Call DC Health Link at (855) 532-5465 to find out if this issue can be resolved. If it can, DC Health Link can check again to see if <Person First Name> would be eligible."
      end
      if ivl[:is_medicaid_chip_eligible] == false
        flag = true
        block << "<Person First Name> does not qualify for an advance premium tax credit to help pay for the insurance because this person has access to what the federal government considers affordable coverage. "
      end
      aptc_block << block if flag == true
      rows << aptc_block if aptc_block.count > 1

      csr_block = []
      csr_block << "Cost-Sharing Reductions (CSR)"
      block = []
      flag = false 
      if ivl[:is_medicaid_chip_eligible] == false
        flag = true
        block << "<Person First Name> qualifies for cost-sharing reductions, but must select a silver plan to receive them. Your annual household income of <$annual household income> is within the income limit of <$CSR annual income limit>. With a silver plan, <Person First Name> will get a discount on what they pay for medical services."
      end
      if ivl[:is_medicaid_chip_eligible] == false
        flag = true
        block << "<Person First name> qualifies for plans with no cost sharing. Your annual household income of <$annual household income> is within the income limit of <$CSR annual income limit>, and you indicated that <Person First Name> is a member of a federally recognized tribe. This means services covered by a health plan’s network, such as doctor visits, medicines, or emergency care won’t cost anything. Services provided by an Indian Health Service facility are also free."
      end
      if ivl[:is_medicaid_chip_eligible] == false
        flag = true
        block << "<Person First Name> qualifies for limited cost-sharing. You indicated that <Person First Name> is a member of a federally recognized tribe. This means <Person First Name> won’t have to pay for services covered by a health plan’s network, such as doctor visits, medicines, or emergency care if this person gets care through the Indian Health Service, Tribal Health Providers, or Urban Indian Health Providers (I/T/U). This person must have a referral from an I/T/U provider to receive covered services from another in-network service provider at no cost."
      end
      if ivl[:is_medicaid_chip_eligible] == false
        flag = true
        block << "<Person First Name> does not qualify for cost-sharing reductions because your annual household income of <$annual household income> is over the income limit of <$CSR annual allowable limit>."
      end
      if ivl[:is_medicaid_chip_eligible] == false
        flag = true
        block << "<Person First Name> does not qualify for cost-sharing reductions because this person is likely eligible for Medicaid."
      end
      if ivl[:is_medicaid_chip_eligible] == false
        flag = true
        block << "<Person First Name> does not qualify for cost-sharing reductions for one of the following reasons:
          Not filing taxes for <coverage year>
          Filed taxes separately from spouse for <coverage year>
          Did not reconcile the tax credit received in a previous year on this person’s federal tax return
          Call DC Health Link at (855) 532-5465 to find out if this issue can be resolved. If it can, DC Health Link can check again to see if <person first name> would be eligible."
      end
      if ivl[:is_medicaid_chip_eligible] == false
        flag = true
        block << "<Person First Name> does not qualify for cost-sharing reductions because this person has access to what the federal government considers affordable coverage."
      end
      csr_block << block if flag == true
      rows << csr_block if csr_block.count > 1

      ineligible_for_medicaid = []
      ineligible_for_medicaid << "Ineligible for Medicaid and Private Health Insurance"
      block = []
      flag = false
      if ivl[:is_medicaid_chip_eligible] == false
        flag = true
        block << "<Person First Name> does not qualify for Medicaid or private health insurance (with or without help paying for coverage). The reason is because <insert reason>. [If more than one reason]In addition, <Insert next reason with period at the end> [Insert after reason(s)]If <Dependent First Name>’s status changes, we encourage you to update your application, or call DC Health Link at (855) 532-5465."
      end
      ineligible_for_medicaid << block if flag == true
      rows << ineligible_for_medicaid if ineligible_for_medicaid.count > 1
      rows
    end
  end
end