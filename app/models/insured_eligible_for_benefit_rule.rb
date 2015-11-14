class InsuredEligibleForBenefitRule
  include Acapi::Notifiers

  # Insured role can be: EmployeeRole, ConsumerRole, ResidentRole


  # ACA_ELIGIBLE_CITIZEN_STATUS_KINDS = %W(
  #     us_citizen
  #     naturalized_citizen
  #     indian_tribe_member
  #     alien_lawfully_present
  #     lawful_permanent_resident
  # )

  def initialize(role, benefit_package, coverage_kind='health')
    @role = role
    @benefit_package = benefit_package
    @coverage_kind = coverage_kind
  end

  def setup
    hbx = HbxProfile.current_hbx
    bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bp| bp.start_on.year == 2015 }
    ivl_health_benefits_2015 = bc_period.benefit_packages.detect { |bp| bp.title == "individual_health_benefits_2015" }

    person = Person.where(last_name: "Murray").entries.first
    if person.consumer_role.nil?
      consumer_role = person.build_consumer_role(is_applicant: true)
      consumer_role.save!
      consumer_role
    else
      consumer_role = person.consumer_role
    end

    # rule = InsuredEligibleForBenefitRule.new(consumer_role, ivl_health_benefits_2015)
    # rule.satisfied?
  end

  def satisfied?
    if @role.class.name == "ConsumerRole"
      @errors = []
      status = @benefit_package.benefit_eligibility_element_group.class.fields.keys.reject{|k| k == "_id"}.reduce(true) do |eligible, element|
        if self.public_send("is_#{element}_satisfied?")
          true && eligible
        else
          @errors << ["eligibility failed on #{element}"]
          false
        end
      end
      return status, @errors
    end
    [false]
  end

  def is_cost_sharing_satisfied?
    cost_sharing = @benefit_package.cost_sharing
    csr_kind = @role.try(:person).try(:primary_family).try(:latest_household).try(:latest_active_tax_household).try(:latest_eligibility_determination).try(:csr_eligibility_kind)

    return true if csr_kind.blank? or cost_sharing.blank?
    csr_kind == cost_sharing
  rescue => e
    log("call is_cost_sharing_satisfied? error: #{e.message}", {:severity => "error"})
    true
  end

  def is_medicaid_eligibility_satisfied?
    required_status = @benefit_package.medicaid_eligibility
    return true if required_status.include? "any"
    return true if tax_household_member.blank?

    status = tax_household_member.is_medicaid_chip_eligible? ? "eligible" : "non_eligible"
    required_status.include? status
  end

  def is_applicant_status_satisfied?
    required_status = @benefit_package.applicant_status
    return true if required_status.include? "any"

    status = @role.is_applicant ? "applicant" : "non_applicant"
    required_status.include? status
  end

  def is_market_places_satisfied?
    true
  end

  def is_enrollment_periods_satisfied?
    true
  end

  def is_family_relationships_satisfied?
    true
  end

  def is_benefit_categories_satisfied?
    @benefit_package.benefit_categories.include? @coverage_kind
  end

  def is_citizenship_status_satisfied?
    true
  end

  def is_ethnicity_satisfied?
    true
  end

  def is_residency_status_satisfied?
    return true if @benefit_package.residency_status.include?("any")

    if @benefit_package.residency_status.include?("state_resident") and @role.present?
      person = @role.person
      return true if person.is_dc_resident?

      #TODO person can have more than one families
      person.families.last.family_members.active.each do |family_member|
        if age_on_next_effective_date(family_member.dob) >= 19 and family_member.is_dc_resident?
          return true
        end
      end
    end
    return false
  end

  def is_incarceration_status_satisfied?
    return true if @benefit_package.incarceration_status.include?("any")
    @benefit_package.incarceration_status.include?("unincarcerated") && !@role.is_incarcerated?
  end

  def is_age_range_satisfied?
    return true if @benefit_package.age_range == (0..0)

    age = age_on_next_effective_date(@role.dob)
    @benefit_package.age_range.cover?(age)
  end

  def determination_results
    @errors
  end

  # def fails_market_places?
  #   if passes
  #     false
  #   else
  #     reason
  #   end
  # end

  def age_on_next_effective_date(dob)
    today = TimeKeeper.date_of_record
    today.day <= 15 ? age_on = today.end_of_month + 1.day : age_on = (today + 1.month).end_of_month + 1.day
    age_on.year - dob.year - ((age_on.month > dob.month || (age_on.month == dob.month && age_on.day >= dob.day)) ? 0 : 1)
  end

  def tax_households
    begin
      year = @benefit_package.benefit_coverage_period.start_on.year

      tax_households = @role.person.families.map do |family|
        family.latest_active_tax_household_with_year(year)
      end
      tax_households.compact
    rescue => e
      log("get tax_household error: #{e.message}, consumer_role: #{@role.id}", {:severity => "error"})
      []
    end
  end

  def tax_household_member
    return nil if tax_households.blank?

    members = tax_households.map(&:tax_household_members).uniq
    members.detect {|member| member.applicant_id == @role.applicant_id}
  end
end
