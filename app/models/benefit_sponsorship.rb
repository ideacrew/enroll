class BenefitSponsorship
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :hbx_profile
  # embedded_in :employer_profile

  SERVICE_MARKET_KINDS = %w(shop individual)

  field :service_markets, type: Array, default: []

  # 2015, 2016, etc. (aka plan_year)
  embeds_many :benefit_coverage_periods
  embeds_many :geographic_rating_areas

  accepts_nested_attributes_for :benefit_coverage_periods, :geographic_rating_areas

# effective_coverage_period
# HBX: Jan-Dec
# Employers: year-over-year, e.g. Jun-May

# Shopping time range
# Benefit effective time range: can exceed one year
# Issuer begin date
# Issuer end date -- 

# Employer
# Effective start on date: Dec 1, 2015
# Effective end on date: Nov 30, 2016
# (policy) contract start on date
# (policy) contract end on date

# SHOP plan effective start on date Jan 1, 2015
# SHOP plan effective end on date: Dec 31, 2015

# product effective_start_on
# product effective_end_on

# 2015 SHOP plan that becomes effective Jan 1 2015
#   benefit_service_period between Jan 1 2015 and Nov 30, 2016

  class << self
    def advance_day(new_date)

      # Employer activities that take place monthly - on first of month
      if new_date.day == 1
        orgs = Organization.exists(:"employer_profile.employer_profile_account._id" => true).not_in(:"employer_profile.employer_profile_account.aasm_state" => %w(canceled terminated))
        orgs.each do |org|
          org.employer_profile.employer_profile_account.advance_billing_period!
        end
      end

      # Find employers with events today and trigger their respective workflow states
      orgs = Organization.or(
        {:"employer_profile.plan_years.start_on" => new_date},
        {:"employer_profile.plan_years.end_on" => new_date - 1.day},
        {:"employer_profile.plan_years.open_enrollment_start_on" => new_date},
        {:"employer_profile.plan_years.open_enrollment_end_on" => new_date - 1.day},
        {:"employer_profile.workflow_state_transitions".elem_match => {
            "$and" => [
              {:transition_at.gte => (new_date.beginning_of_day - HbxProfile::ShopApplicationIneligiblePeriodMaximum)},
              {:transition_at.lte => (new_date.end_of_day - HbxProfile::ShopApplicationIneligiblePeriodMaximum)},
              {:to_state => "ineligible"}
            ]
          }
        }
      )

      orgs.each do |org|
        org.employer_profile.today = new_date
        org.employer_profile.advance_date! if org.employer_profile.may_advance_date?
        plan_year = org.employer_profile.published_plan_year
        plan_year.advance_date! if plan_year && plan_year.may_advance_date?
        plan_year
      end
    end
  end
end
