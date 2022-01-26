# draft module for all the logic used in aptc calculation

module HouseholdModule 
    module CalculateMaxAptc < Household
        # check for the usage of effective on param
        def total_aptc_available_amount_for_enrollment(hbx_enrollment, effective_on = nil, excluding_enrollment = nil)
        effective_on = effective_on || hbx_enrollment.effective_on
        return 0 if hbx_enrollment.blank?
        return 0 if is_all_non_aptc?(hbx_enrollment, effective_on)
        monthly_available_aptc = monthly_max_aptc(hbx_enrollment, effective_on)
        member_aptc_hash = aptc_available_amount_by_member(monthly_available_aptc, excluding_enrollment)
        total = family.active_family_members.reduce(0) do |sum, member|
            sum + (member_aptc_hash[member.id.to_s] || 0)
        end
        family_members = unwanted_family_members(hbx_enrollment)
        unchecked_aptc_thhms = find_aptc_tax_household_members(family_members)
        deduction_amount = total_benchmark_amount(unchecked_aptc_thhms, hbx_enrollment) if unchecked_aptc_thhms
        total = total - deduction_amount
        (total < 0.00) ? 0.00 : float_fix(total)
        end

          # to check if all the enrolling family members are not aptc
        def is_all_non_aptc?(hbx_enrollment, effective_on)
            find_enrolling_fms(hbx_enrollment)
            find_non_aptc_fms(@enrolling_family_members, effective_on).count == @enrolling_family_members.count
        end

        # to get family members from given enrollment
        def find_enrolling_fms hbx_enrollment
            @enrolling_family_members ||= hbx_enrollment.hbx_enrollment_members.map(&:family_member)
        end

        # to get non aptc fms from given family members
        # 1 st THH - fm 1 - ia_eligible : false
        # 2nd THH - fm 2, fm 3 - ia_eligible : true
        def find_non_aptc_fms(family_members, effective_on )
            @active_tax_households = active_tax_households_for_year(effective_on.year)
            family_member_ids = family_members.pluck(:id)
            eligible_tax_households = active_tax_households.where(:"tax_household_members.family_member_id".in => family_member_ids, :"tax_household_members.is_ia_eligible" => false)
            
            non_aptc_thhms = eligible_tax_households.map(&:tax_household_members).select{|thhm| family_member_ids.include?(thhm.applicant_id) && !thhm.is_ia_eligible.present? }.flatten
            non_aptc_thhms.map(&:family_members)
        end

        def monthly_max_aptc(hbx_enrollment, effective_on)
            @active_tax_households ||= active_tax_households_for_year(effective_on.year)
            monthly_max_aggregate = if EnrollRegistry[:calculate_monthly_aggregate].feature.is_enabled && @active_tax_households == 1
                                      shopping_fm_ids = hbx_enrollment.hbx_enrollment_members.pluck(:applicant_id)
                                      input_params = { family: hbx_enrollment.family,
                                                       effective_on: effective_on,
                                                       shopping_fm_ids: shopping_fm_ids,
                                                       subscriber_applicant_id: hbx_enrollment&.subscriber&.applicant_id }
                                      monthly_aggregate_amount = EnrollRegistry[:calculate_monthly_aggregate] {input_params}
                                      monthly_aggregate_amount.success? ? monthly_aggregate_amount.value! : 0
                                    else
                                      current_max_aptc(hbx_enrollment).to_f
                                    end
            float_fix(monthly_max_aggregate)
          end

          def current_max_aptc(enrollment)
            return 0 if enrollment.hbx_enrollment_members.count < 1
            @active_tax_households ||= active_tax_households_for_year(effective_on.year)
            find_enrolling_fms(hbx_enrollment)
            eligible_tax_households = @active_tax_households.where(:"tax_household_members.family_member_id".in => @enrolling_family_members.pluck(:id), :"tax_household_members.is_ia_eligible" => true)
            eligible_tax_households
            eligibility_determinations = @active_tax_households.map(&:eligibility_determinations)

            # TODO: need business rule to decide how to get the max aptc
            # during open enrollment and determined_at
            # Please reference ticket 42408 for more info on the determined on to determined_at migration
            if eligibility_determinations.present? #and eligibility_determination.determined_at.year == TimeKeeper.date_of_record.year
                eligibility_determinations.max_aptc
            else
              0
            end
          end

  end
end