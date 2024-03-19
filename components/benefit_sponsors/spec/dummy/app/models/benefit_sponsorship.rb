# frozen_string_literal: true

class BenefitSponsorship
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :hbx_profile

  SERVICE_MARKET_KINDS = %w[shop individual coverall].freeze

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

    benefit_coverage_periods.create!(bcp_create_params(year))
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
    current_benefit_period&.earliest_effective_date
  end

  def benefit_coverage_period_by_effective_date(effective_date)
    benefit_coverage_periods.detect { |bcp| bcp.contains?(effective_date) }
  end

  def is_coverage_period_under_open_enrollment?
    benefit_coverage_periods.any? do |benefit_coverage_period|
      benefit_coverage_period.open_enrollment_contains?(TimeKeeper.date_of_record)
    end
  end

  def self.find(id)
    orgs = Organization.where("hbx_profile.benefit_sponsorship._id" => BSON::ObjectId.from_string(id))
    orgs.empty? ? nil : orgs.first.hbx_profile.benefit_sponsorship
  end

  def current_benefit_period
    if renewal_benefit_coverage_period&.open_enrollment_contains?(TimeKeeper.date_of_record)
      renewal_benefit_coverage_period
    else
      current_benefit_coverage_period
    end
  end

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

    # Creates BCP for the prospective year
    def create_prospective_year_benefit_coverage_period(new_date)
      return unless eligible_for_new_benefit_coverage_period?(new_date)

      HbxProfile.current_hbx.benefit_sponsorship.create_benefit_coverage_period(new_date.year.next)
    rescue StandardError => e
      Rails.logger.error { "Couldn't create prospective year benefit coverage period due to #{e.inspect}" }
    end

    def eligible_for_new_benefit_coverage_period?(new_date)
      FinancialAssistanceRegistry.feature_enabled?(:create_bcp_on_date_change) &&
        new_date.month == FinancialAssistanceRegistry[:create_bcp_on_date_change].settings(:bcp_creation_month).item &&
        new_date.day == FinancialAssistanceRegistry[:create_bcp_on_date_change].settings(:bcp_creation_day).item
    end
  end

  private

  def bcp_create_params(year)
    previous_bcp = benefit_coverage_periods.by_year(year.pred).first

    if previous_bcp.present?
      {
        title: "Individual Market Benefits #{year}",
        service_market: previous_bcp.service_market,
        start_on: previous_bcp.start_on.next_year,
        end_on: previous_bcp.end_on.next_year,
        open_enrollment_start_on: previous_bcp.open_enrollment_start_on.next_year,
        open_enrollment_end_on: previous_bcp.open_enrollment_end_on.next_year
      }
    else
      {
        title: "Individual Market Benefits #{year}",
        service_market: 'individual',
        start_on: Date.new(year, 1, 1),
        end_on: Date.new(year, 12, 31),
        open_enrollment_start_on: Date.new(year.pred, 11, 1),
        open_enrollment_end_on: Date.new(year, 1, 31)
      }
    end
  end
end
