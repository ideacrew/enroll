class BenefitSponsorship
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :hbx_profile
  # embedded_in :employer_profile

  # person/roles can determine which sponsor in a class has a relationship (offer products)
  # which benefit packages should be offered to person/roles

  SERVICE_MARKET_KINDS = %w(shop individual coverall)

  field :service_markets, type: Array, default: []
  validates_presence_of :service_markets

  # 2015, 2016, etc. (aka plan_year)
  embeds_many :benefit_coverage_periods
  embeds_many :geographic_rating_areas

  accepts_nested_attributes_for :benefit_coverage_periods, :geographic_rating_areas
  # Query Census member collection
  def census_employees
    @census_employees = CensusMembers::PlanDesignCensusEmployee.by_benefit_sponsorship(self)
  end

  def create_benefit_coverage_period(year)
    bcp = benefit_coverage_periods.by_year(year).first
    return bcp if bcp.present?

    previous_bcp = benefit_coverage_periods.by_year(year.pred).first
    benefit_coverage_periods.create!(
      {
        title: "Individual Market Benefits #{year}",
        service_market: previous_bcp&.service_market || 'individual',
        start_on: previous_bcp&.start_on&.next_year || Date.new(year, 1, 1),
        end_on: previous_bcp&.end_on&.next_year || Date.new(year, 12, 31),
        open_enrollment_start_on: previous_bcp&.open_enrollment_start_on&.next_year || Date.new(year.pred, 11, 1),
        open_enrollment_end_on: previous_bcp&.open_enrollment_end_on&.next_year || Date.new(year, 1, 31)
      }
    )
  end

  def current_benefit_coverage_period
    benefit_coverage_periods.detect { |bcp| bcp.contains?(TimeKeeper.date_of_record) }
  end

  def renewal_benefit_coverage_period
    benefit_coverage_periods.detect { |bcp| bcp.contains?(TimeKeeper.date_of_record + 1.year) }
  end

  def previous_benefit_coverage_period
    benefit_coverage_periods.detect { |bcp| bcp.contains?(TimeKeeper.date_of_record - 1.year) }
  end

  def earliest_effective_date
    current_benefit_period.earliest_effective_date if current_benefit_period
  end

  def benefit_coverage_period_by_effective_date(effective_date)
    benefit_coverage_periods.detect { |bcp| bcp.contains?(effective_date) }
  end


  # def is_under_special_enrollment_period?
  #   benefit_coverage_periods.detect { |bcp| bcp.contains?(TimeKeeper.date_of_record) }
  # end

  def is_coverage_period_under_open_enrollment?
    benefit_coverage_periods.any? do |benefit_coverage_period|
      benefit_coverage_period.open_enrollment_contains?(TimeKeeper.date_of_record)
    end
  end

  def self.find(id)
    orgs = Organization.where("hbx_profile.benefit_sponsorship._id" => BSON::ObjectId.from_string(id))
    orgs.size > 0 ? orgs.first.hbx_profile.benefit_sponsorship : nil
  end

  def current_benefit_period
    if renewal_benefit_coverage_period && renewal_benefit_coverage_period.open_enrollment_contains?(TimeKeeper.date_of_record)
      renewal_benefit_coverage_period
    else
      current_benefit_coverage_period
    end
  end

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
      create_prospective_year_benefit_coverage_period(new_date)

      hbx_sponsors = Organization.exists("hbx_profile.benefit_sponsorship": true).reduce([]) { |memo, org| memo << org.hbx_profile }

      hbx_sponsors.each do |hbx_sponsor|
        hbx_sponsor.advance_day
        hbx_sponsor.advance_month   if new_date.day == 1
        hbx_sponsor.advance_quarter if new_date.day == 1 && [1, 4, 7, 10].include?(new_date.month)
        hbx_sponsor.advance_year    if new_date.day == 1 && new_date.month == 1
      end

      renewal_benefit_coverage_period = HbxProfile.current_hbx.benefit_sponsorship.renewal_benefit_coverage_period
      return unless EnrollRegistry.feature_enabled?(:ivl_enrollment_renewal_begin_date)
      oe_month = EnrollRegistry[:ivl_enrollment_renewal_begin_date].setting(:ivl_enrollment_renewal_begin_effective_month).item
      oe_day_of_month = EnrollRegistry[:ivl_enrollment_renewal_begin_date].setting(:ivl_enrollment_renewal_begin_effective_day).item
      renewal_oe_date = Date.new(TimeKeeper.date_of_record.year, oe_month, oe_day_of_month)
      return unless renewal_benefit_coverage_period.present? && renewal_oe_date == new_date && !Rails.env.test?
      oe_begin = Enrollments::IndividualMarket::OpenEnrollmentBegin.new
      oe_begin.process_renewals
    end

    def create_prospective_year_benefit_coverage_period(new_date)
      return unless eligible_for_new_benefit_coverage_period?(new_date)

      HbxProfile.current_hbx.benefit_sponsorship.create_benefit_coverage_period(new_date.year)
    rescue StandardError => e
      Rails.logger.error { "Couldn't create prospective year benefit coverage period due to #{e.inspect}" }
    end

    def eligible_for_new_benefit_coverage_period?(new_date)
      FinancialAssistanceRegistry.feature_enabled?(:create_bcp_on_date_change) &&
        new_date.month == FinancialAssistanceRegistry[:create_bcp_on_date_change].settings(:bcp_creation_month).item &&
        new_date.day == FinancialAssistanceRegistry[:create_bcp_on_date_change].settings(:bcp_creation_day).item
    end
  end
end
