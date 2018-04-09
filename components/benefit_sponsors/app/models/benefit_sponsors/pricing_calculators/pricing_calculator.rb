module BenefitSponsors
  module PricingCalculators
    class PricingCalculator
        def calc_coverage_age_for(member, eligibility_dates, coverage_start_date)
          coverage_elig_date = eligibility_dates[member.member_id]
          coverage_as_of_date = coverage_elig_date.blank? ? coverage_start_date : coverage_elig_date
          before_factor = if (coverage_as_of_date.month > member.dob.month)
            -1
          elsif ((coverage_as_of_date.month == member.dob.month) && (coverage_as_of_date.day > member.dob.day))
            -1
          else
            0
          end
          coverage_as_of_date.year - member.dob.year + (before_factor)
        end
    end
  end
end
