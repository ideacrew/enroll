class VitalSign
  include Mongoid::Document

  attr_reader :start_at, :end_at

  # DateTime that DCHL Enroll App went live
  ZERO_HOUR = DateTime.new(2015,10,13,9,0,0,'+5')

  def initialize(start_at: ZERO_HOUR, end_at: TimeKeeper.datetime_of_record)
    @start_at = start_at
    @end_at = end_at
  end

  def families_to_eligibility_determinations(family_list)
    family_list.flat_map() do |family|
      family.households.flat_map() do |household|
        household.tax_households.flat_map() do |tax_household|
          tax_household.eligibility_determinations
        end
      end
    end          
  end

  def accounts_created
    User.gte(created_at: @start_at).lte(created_at: @end_at)
  end

  def all_plan_shopping
    Family.and(
        {:"households.hbx_enrollments.created_at".gte => @start_at},
        {:"households.hbx_enrollments.created_at".lte => @end_at}
      ).to_a
  end

  def all_enrollments
    families = Family.all_enrollments.and(
        {:"households.hbx_enrollments.created_at".gte => @start_at},
        {:"households.hbx_enrollments.created_at".lte => @end_at}
      ).to_a

    @all_enrollments = families.flat_map() do |family|
      family.households.flat_map() do |household|
        household.hbx_enrollments.enrolled.gte(created_at: @start_at).lte(created_at: @end_at).and(:aasm_state.in => HbxEnrollment::ENROLLED_STATUSES)
      end
    end
  end

  def all_individual_eligibility_determinations
    families = Family.and(
        {:"households.tax_households.eligibility_determinations.determined_on".gte => @start_at},
        {:"households.tax_households.eligibility_determinations.determined_on".lte => @end_at}
      )

    @all_individual_eligibility_determinations = families.flat_map() do |family|
      family.households.flat_map() do |household|
        household.tax_households.flat_map() do |tax_household|
          tax_household.eligibility_determinations.gte(determined_on: @start_at).lte(determined_on: @end_at)
        end
      end
    end      
  end

  def all_active_individual_eligibility_determinations
    all_individual_eligibility_determinations unless defined? @all_individual_eligibility_determinations
    @all_individual_eligibility_determinations.select { |determination| determination.tax_household.effective_ending_on.blank? }
  end

  def all_active_assistance_eligible_individual_eligibility_determinations
    all_active_individual_eligibility_determinations.select { |determination| determination.max_aptc > 0 }
  end

  def enrollment_counts_by_family
    all_enrollments unless defined? @all_enrollments
    @all_enrollments.reduce(Hash.new(0)) {|counts, hbx_enrollment| counts[hbx_enrollment.household.family._id] += 1; counts }  
  end

  def all_shop_enrollments
    all_enrollments unless defined? @all_enrollments
    @all_enrollments.select { |enrollment| enrollment.kind == "employer_sponsored" }
  end

  def all_individual_enrollments
    all_enrollments unless defined? @all_enrollments
    @all_enrollments.select { |enrollment| enrollment.kind == "individual" }
  end

  def individual_unassisted_qhp_enrollments
    all_individual_enrollments.select { |enrollment| enrollment.household.family.e_case_id.blank? }
  end

  def individual_assisted_qhp_enrollments
    all_individual_enrollments.select { |enrollment| enrollment.household.family.e_case_id.present? }
  end

  def individual_assisted_qhp_enrollments_with_applied_aptc
    all_individual_enrollments.select { |enrollment| enrollment.applied_aptc_amount > 0.0 }
  end

  def is_health_enrollment?(enrollment)
    enrollment.plan.coverage_kind == "health"
  end

  def is_dental_enrollmant?(enrollment)
    enrollment.plan.coverage_kind == "dental"
  end

  def transferred_to_curam
  end

  def accounts_screened
  end

  def iam_new_account_requests
  end

  def ivl_assisted_eligibility_determinations_unmatched
  end


end
