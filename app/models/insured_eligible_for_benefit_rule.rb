class InsuredEligibleForBenefitRule
  include Consumer::EmployeeRolesHelper
  attr_reader :role, :benefit_package

  # Insured can be: employee_role, consumer_role, resident_role

  ACA_ELIGIBLE_CITIZEN_STATUS_KINDS = %W(
      us_citizen
      naturalized_citizen
      indian_tribe_member
      alien_lawfully_present
      lawful_permanent_resident
  )

  def initialize(role, benefit_package)
    @role = role
    @benefit_package = benefit_package
    if @role.class.name == "EmployeeRole"
      @offered_relationship_benefits = @role.benefit_group.relationship_benefits.select(&:offered).map(&:relationship)
    end
  end

  def satisfied?(family_member)
    if @role.class.name == "ConsumerRole" && @benefit_package == "individual"
      member_role = family_member.person.consumer_role
      #hbx = HbxProfile.find_by_state_abbreviation("dc")

      #member_role.is_state_resident? && TODO 
       !member_role.is_incarcerated? &&
        ACA_ELIGIBLE_CITIZEN_STATUS_KINDS.include?(member_role.citizen_status) #&& 
        #(hbx.benefit_sponsorship.benefit_coverage_periods.first.open_enrollment_contains?(TimeKeeper.date_of_record)) ||
        #( # family is under SEP )
        #)

    elsif @role.class.name == "EmployeeRole" && @benefit_package == "shop"
      # employee_role is under open enrollment || employee_role family is under SEP
      coverage_relationship_check(@offered_relationship_benefits, family_member)
    else
      # raise error for role/benefit_package mismatch
    end
  end

  def determination_result
    # eligible
    ## Benefit package's benefit coverage period 
    # no_open_enrollment_period_active
    ## Benefit package
    # no_benefit_for_relationship
    # no_benefit_for_age
    # invalid_relationship_and_age_combination
    ## Role
    # not_a_resident
    # incarcerated
    # unverified_lawful_presence
    # not_lawfully_present
    ## Role's Family
    # no_special_enrollment_period_active
  end

end
