class HbxAdmin
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps

  class << self

    def build_grid_values_for_aptc_csr(family, max_aptc=nil, csr_percentage=nil, member_ids=nil)
        months_array = Date::ABBR_MONTHNAMES.compact
        plan_premium_vals         = build_plan_premium_values(family, months_array)
        aptc_applied_vals         = build_aptc_applied_values(family, months_array)
        avalaible_aptc_vals       = build_avalaible_aptc_values(family, months_array, max_aptc, member_ids)
        max_aptc_vals             = build_max_aptc_values(family, months_array, max_aptc)
        csr_percentage_vals       = build_csr_percentage_values(family, months_array, csr_percentage)
        slcsp_values              = build_slcsp_values(family, months_array, member_ids)
        individuals_covered_vals  = build_individuals_covered_array(family, months_array)
        eligible_members_vals     = build_eligible_members(family, months_array, member_ids)

        return { "plan_premium"         => plan_premium_vals,
                 "aptc_applied"         => aptc_applied_vals,
                 "avalaible_aptc"       => avalaible_aptc_vals,
                 "max_aptc"             => max_aptc_vals,
                 "csr_percentage"       => csr_percentage_vals,
                 "slcsp"                => slcsp_values, 
                 "individuals_covered"  => individuals_covered_vals,
                 "eligible_members"     => eligible_members_vals 
                }
    end

    def build_plan_premium_values(family, months_array)
      hbx = family.active_household.hbx_enrollments_with_aptc_by_year(TimeKeeper.datetime_of_record.year).last

      plan_premium_hash = Hash.new
      months_array.each_with_index do |month, ind|
        plan_premium_hash.store(month, hbx.try(:total_premium) || false)
      end
      return plan_premium_hash
    end

    def build_aptc_applied_values(family, months_array)
      #hbxs = family.active_household.hbx_enrollments_with_aptc_by_year(TimeKeeper.datetime_of_record.year)
      eligibility_determinations = family.active_household.latest_active_tax_household.eligibility_determinations
      #applied_aptc = hbxs.map{|h| h.applied_aptc_amount.to_f}.sum
      aptc_applied_hash = Hash.new
      months_array.each_with_index do |month, ind|
        eligibility_determinations.each do |ed|
          update_aptc_applied_hash_for_month(aptc_applied_hash, month, ed, family)
          #aptc_applied_hash.store(month, applied_aptc)
        end
      end
      return aptc_applied_hash
    end

    def update_aptc_applied_hash_for_month(aptc_applied_hash, month, ed, family)
      hbxs = family.active_household.hbx_enrollments_with_aptc_by_year(TimeKeeper.datetime_of_record.year)
      applied_aptc = hbxs.map{|h| h.applied_aptc_amount.to_f}.sum
      first_of_month_num_current_year = first_of_month_converter(month)
      if first_of_month_num_current_year >= ed.determined_on
        aptc_applied_hash.store(month, applied_aptc)
      else
        aptc_applied_hash.store(month, "---")
      end  
    end


    def build_avalaible_aptc_values(family, months_array, max_aptc=nil, member_ids=nil)

      available_aptc_hash = Hash.new
      eligibility_determinations = family.active_household.latest_active_tax_household.eligibility_determinations

      months_array.each_with_index do |month, ind|
        eligibility_determinations.each do |ed|

          update_available_aptc_hash_for_month(available_aptc_hash, month, ed, family, max_aptc, member_ids)
        #avalaible_aptc_hash.store(month, family.active_household.latest_active_tax_household.total_aptc_available_amount)
        end
      end
      return available_aptc_hash
    end

    def update_available_aptc_hash_for_month(available_aptc_hash, month, ed, family, max_aptc=nil, member_ids=nil)
      first_of_month_num_current_year = first_of_month_converter(month)

      if max_aptc.present? && member_ids.present?
        hbxs = family.active_household.hbx_enrollments_with_aptc_by_year(TimeKeeper.datetime_of_record.year)
        applied_aptc = hbxs.map(&:hbx_enrollment_members).flatten.select{|hm| member_ids.include?(hm.person.id.to_s) }.map{|h| h.applied_aptc_amount.to_f }.sum
        available_aptc = max_aptc - applied_aptc
      else
        available_aptc = family.active_household.latest_active_tax_household.total_aptc_available_amount
      end
      if first_of_month_num_current_year >= ed.determined_on
        available_aptc_hash.store(month, available_aptc)
      else
        available_aptc_hash.store(month, "---")
      end  
    end

    def build_max_aptc_values(family, months_array, max_aptc=nil)
      max_aptc_hash = Hash.new
      eligibility_determinations = family.active_household.latest_active_tax_household.eligibility_determinations
      months_array.each_with_index do |month, ind|
        # iterate over all the EligibilityDeterminations and store the correct max_aptc value for each month. Account for any monthly change in Eligibility Determination.
        eligibility_determinations.each do |ed|
          update_max_aptc_hash_for_month(max_aptc_hash, month, ed, max_aptc)
        end  
        #max_aptc_hash.store(month, family.active_household.tax_households[0].eligibility_determinations.first.max_aptc.fractional)
        #max_aptc_hash.store(month, family.active_household.latest_active_tax_household.current_max_aptc.to_f)
      end
      return max_aptc_hash
    end

    def update_max_aptc_hash_for_month(max_aptc_hash, month, ed, max_aptc=nil)
      first_of_month_num_current_year = first_of_month_converter(month)

      max_aptc_value = max_aptc.present? ? max_aptc : ed.max_aptc.to_f
      # Check if  'month' >= EligibilityDetermination.determined_on date?
      if first_of_month_num_current_year >= ed.determined_on
        # assign that month with aptc_max value from this ed (EligibilityDetermination)
        max_aptc_hash.store(month, max_aptc_value)
      else
        # update max_aptc value for that month as a "---"
        max_aptc_hash.store(month, "---")
      end  
    end



    def build_csr_percentage_values(family, months_array, csr_percentage=nil)
      csr_percentage_hash = Hash.new
      eligibility_determinations = family.active_household.latest_active_tax_household.eligibility_determinations
      months_array.each_with_index do |month, ind|
        eligibility_determinations.each do |ed|
          update_csr_percentages_hash_for_month(csr_percentage_hash, month, ed, csr_percentage)
        end 
        #csr_percentage_hash.store(month, (family.active_household.latest_active_tax_household.current_csr_percent*100).to_s + " %")
      end
      return csr_percentage_hash
    end

    def update_csr_percentages_hash_for_month(csr_percentage_hash, month, ed, csr_percentage=nil)
      first_of_month_num_current_year = first_of_month_converter(month)

      csr_percentage_value = csr_percentage.present? ? csr_percentage : ed.csr_percent_as_integer
      # Check if  'month' >= EligibilityDetermination.determined_on date?
      if first_of_month_num_current_year >= ed.determined_on
        # assign that month with csr_percent value from this ed (EligibilityDetermination)
        csr_percentage_hash.store(month, csr_percentage_value)
      else
        # update csr_percent value for that month as a "-"
        csr_percentage_hash.store(month, "---")
      end  
    end

    def first_of_month_converter(month)
      month_num = Date::ABBR_MONTHNAMES.index(month.capitalize || month) # coverts Month name to Month Integer : "jan" -> 1
      current_year = TimeKeeper.date_of_record.year
      first_of_month_num_current_year = Date.parse("#{current_year}-#{month_num}-01")
      return first_of_month_num_current_year
    end  

    def build_slcsp_values(family, months_array, member_ids=nil)
      benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
      eligibility_determinations = family.active_household.latest_active_tax_household.eligibility_determinations
      benefit_coverage_period = benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(TimeKeeper.datetime_of_record)}
      slcsp = benefit_coverage_period.second_lowest_cost_silver_plan

      if member_ids.present?
        aptc_members = family.active_household.latest_active_tax_household.tax_household_members.select {|m| member_ids.include?(m.person.id.to_s) }
      else
        aptc_members = family.active_household.latest_active_tax_household.aptc_members
      end

      cost = aptc_members.map do |member|
        slcsp.premium_for(TimeKeeper.datetime_of_record, member.age_on_effective_date)
      end.inject(:+) || 0
          
      slcsp_hash = Hash.new
      months_array.each_with_index do |month, ind|
        eligibility_determinations.each do |ed|
          first_of_month_num_current_year = first_of_month_converter(month)
            if first_of_month_num_current_year >= ed.determined_on
              slcsp_hash.store(month, cost)
            else
              slcsp_hash.store(month, "---")
            end  
          
        end
      end
      return slcsp_hash
    end

    def build_individuals_covered_array(family, months_array)
      individuals_covered_array = Array.new
      eligibility_determinations = family.active_household.latest_active_tax_household.eligibility_determinations
      family.family_members.each_with_index do |one_member, index|
          covered_hash = Hash.new
            months_array.each_with_index do |month, ind|
                eligibility_determinations.each do |ed|
                  first_of_month_num_current_year = first_of_month_converter(month)
                  if first_of_month_num_current_year >= ed.determined_on
                    covered_hash.store(month, true)
                  else
                    covered_hash.store(month, false)
                  end 
                end
            end
           individuals_covered_array << {one_member.person.id.to_s => covered_hash} 
      end
      return individuals_covered_array
    end


    def build_eligible_members(family, months_array, member_ids=nil)
      return member_ids if member_ids.present?

      eligible_members = Array.new
      tax_household_members = family.active_household.latest_active_tax_household_with_year(TimeKeeper.date_of_record.year).try(:tax_household_members)
      tax_household_members.each do |member|
        if member.is_ia_eligible
          eligible_members << member.person.id.to_s
        end
      end
      return eligible_members
    end
    ###

  end


end
