module BenefitSponsors
  module ContributionCalculators
    class ContributionCalculator

      # Calculate contributions for the given entry
      # @param contribution_model [BenefitMarkets::ContributionModel] the
      #   contribution model for this calculation
      # @param priced_roster_entry [BenefitMarkets::SponsoredBenefits::PricedRosterEntry]
      #   the roster entry for which to provide contribution
      # @param sponsor_contribution [BenefitSponsors::SponsoredBenefits::SponsorContribution]
      #   the concrete values for contributions
      # @return [BenefitMarkets::SponsoredBenefits::ContributionRosterEntry] the
      #   contribution results paired with the roster
      def calculate_contribution_for(contribution_model, priced_roster_entry, sponsor_contribution)
        raise NotImplementedError.new("subclass responsiblity")
      end

      def calc_coverage_age_for(eligibility_dates, coverage_start_date, member, product, previous_product)
        coverage_elig_date = eligibility_dates[member.member_id]
        coverage_as_of_date = if (!previous_product.blank?) && (product.id == previous_product.id) && (!coverage_elig_date.blank?)
                                coverage_elig_date
                              else
                                coverage_start_date
                              end
        before_factor = if (coverage_as_of_date.month < member.dob.month)
                          -1
                        elsif ((coverage_as_of_date.month == member.dob.month) && (coverage_as_of_date.day < member.dob.day))
                          -1
                        else
                          0
                        end
        coverage_as_of_date.year - member.dob.year + (before_factor)
      end
    end
  end
end
