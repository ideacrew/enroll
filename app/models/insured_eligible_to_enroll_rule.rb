class InsuredEligibleToEnrollRule
  include Mongoid::Document
  include Consumer::EmployeeRolesHelper
  attr_reader :role, :market

  ACA_ELIGIBLE_CITIZEN_STATUS_KINDS = %W(
      us_citizen
      naturalized_citizen
      indian_tribe_member
      alien_lawfully_present
      lawful_permanent_resident
  )

  def initialize(role, market)
    @role = role
    @market = market.to_s.downcase
    if @role.class.name == "EmployeeRole"
      @offered_relationship_benefits = @role.benefit_group.relationship_benefits.select(&:offered).map(&:relationship)
    end
  end

  def satisfied(family_member)
    if @role.class.name == "ConsumerRole" && @market == "individual"
      member_role = family_member.person.consumer_role
      #hbx = HbxProfile.find_by_state_abbreviation("dc")

      #member_role.is_state_resident? && TODO 
       !member_role.is_incarcerated? &&
        ACA_ELIGIBLE_CITIZEN_STATUS_KINDS.include?(member_role.citizen_status) #&& 
        #(hbx.benefit_sponsorship.benefit_coverage_periods.first.open_enrollment_contains?(TimeKeeper.date_of_record)) ||
        #( # family is under SEP )
        #)

    elsif @role.class.name == "EmployeeRole" && @market == "shop"
      # employee_role is under open enrollment || employee_role family is under SEP
      coverage_relationship_check(@offered_relationship_benefits, family_member)
    else
      # raise error for role/market mismatch
    end
  end
end