class TaxHousehold
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasFamilyMembers

  # A set of applicants, grouped according to IRS and ACA rules, who are considered a single unit
  # when determining eligibility for Insurance Assistance and Medicaid

  embedded_in :household

  auto_increment :hbx_assigned_id, seed: 9999  # Create 'friendly' ID to publish for other systems

  field :allocated_aptc, type: Money, default: 0.00
  field :is_eligibility_determined, type: Boolean, default: false

  field :effective_starting_on, type: Date
  field :effective_ending_on, type: Date
  field :submitted_at, type: DateTime

  embeds_many :tax_household_members
  accepts_nested_attributes_for :tax_household_members

  embeds_many :eligibility_determinations

  def aptc_members
    tax_household_members.find_all(&:is_ia_eligible?)
  end

  def aptc_ratio_by_member
    # if APTC is $100, we need to apportion it between member
    # For example, given family of 4, with 2 adults & 2 children, all who are eligible
    # Based on SLCSP, we will compute ratio for each member based on premium cost
    # So, if total family premium cost is $1,000, adult premium cost is $350/each and
    # child premium cost is $150/each, APTC ratio will be 35% to each adult and 
    # 15% to each child


    # Benchmark Plan: use SLCSP premium rates to determine ratios
    benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
    current_benefit_coverage_period = benefit_sponsorship.current_benefit_coverage_period
    slcsp = current_benefit_coverage_period.second_lowest_cost_silver_plan

    # Look up premiums for each aptc_member

    # Sum premium total for aptc_members

    # Compute the ratio

    {} 
  end

  def aptc_available_amount_by_member
    # Find HbxEnrollments for aptc_members in the current plan year where they have used aptc
    # subtract from available amount
  end
 
  # Pass a list of tax_household_members and get amount of APTC available
  def aptc_available_amount_for_enrollment(members, plan)
    # APTC may be used only for Health
    return 0 if plan.coverage_kind == "dental"


    # premium_total = as_dollars(policy.pre_amt_tot)
    # given_aptc = as_dollars(policy.applied_aptc)
    # max_aptc = as_dollars(premium_total * plan.ehb)
    # correct_aptc = (given_aptc > max_aptc) ? max_aptc : given_aptc
    # policy.applied_aptc = correct_aptc

    # $70
  end


  # Income sum of all tax filers in this Household for specified year
  def total_incomes_by_year
    applicant_links.inject({}) do |acc, per|
      p_incomes = per.financial_statements.inject({}) do |acc, ae|
        acc.merge(ae.total_incomes_by_year) { |k, ov, nv| ov + nv }
      end
      acc.merge(p_incomes) { |k, ov, nv| ov + nv }
    end
  end

  #TODO: return count for adults (21-64), children (<21) and total
  def size
    members.size
  end

  def family
    return nil unless household
    household.family
  end

  def is_eligibility_determined?
    if self.elegibility_determinizations.size > 0
      true
    else
      false
    end
  end

  #primary applicant is the tax household member who is the subscriber
  def primary_applicant
    tax_household_members.detect do |tax_household_member|
      tax_household_member.is_subscriber == true
    end
  end
end
