# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')

# This migration is used for a specific database dump to update benefit applications for testing
class GoldenSeedUpdateBenefitApplicationDates < MongoidMigrationTask
  # Default organization legal names are the employers created in the database dump
  # Otherwise pass in specific names
  DEFAULT_ORGANIZATION_LEGAL_NAMES = ["Broadcasting llc", "Electric Motors Corp", "MRNA Pharma", "Mobile manf crop", "cuomo family Inc"].freeze

  def employer_legal_name_list
    return @employer_legal_name_list if @employer_legal_name_list.present?
    if ENV['target_employer_name_list'].blank?
      puts("No employer name list provided. Using default organizations.")
      @employer_legal_name_list = DEFAULT_ORGANIZATION_LEGAL_NAMES
    else
      puts(
        "Employer name list provided. Changing dates for #{ENV['target_employer_name_list']}"
      )
      @employer_legal_name_list = ENV['target_employer_name_list'].split(",")
    end
  end

  def target_organziations
    if @organization_collection
      @organization_collection
    else
      organization_record_ids = []
      employer_legal_name_list.each do |legal_name|
        organization = BenefitSponsors::Organizations::Organization.where(legal_name: legal_name).first
        organization_record_ids << organization.id.to_s if organization.present?
      end
      raise("No organization record IDs present. Please check legal names.") if organization_record_ids.blank?
      @organization_collection = BenefitSponsors::Organizations::Organization.where(:_id.in => organization_record_ids)
    end
  end

  def benefit_sponsorships_of_organizations
    if @benefit_sponsorships.present?
      @benefit_sponsorships
    else
      @benefit_sponsorships = []
      target_organziations.each do |employer|
        @benefit_sponsorships << employer.active_benefit_sponsorship if employer.active_benefit_sponsorship
      end
    end
    @benefit_sponsorships
  end

  def benefit_applications_of_sponsorships
    if @benefit_applications.present?
      @benefit_applications
    else
      @benefit_applications = []
      benefit_sponsorships_of_organizations.each do |benefit_sponsorship|
        next unless benefit_sponsorship
        benefit_sponsorship.benefit_applications.each do |application|
          @benefit_applications << application
        end
      end
    end
    @benefit_applications
  end

  def update_dates_of_benefit_applications
    benefit_applications_of_sponsorships.each do |benefit_application|
      legal_name = benefit_application.benefit_sponsorship.organization.legal_name
      benefit_application.update_attributes!(effective_period: @coverage_start_on..@coverage_end_on)
      benefit_application.reload
      open_enrollment_period = SponsoredBenefits::BenefitApplications::BenefitApplication.open_enrollment_period_by_effective_date(
        benefit_application.effective_period.min
      )
      benefit_application.update_attributes!(open_enrollment_period: open_enrollment_period)
      puts("Finished updating benefit application for employer #{legal_name}") unless Rails.env.test?
    end
  end

  def recalc_prices_of_benefit_applications
    benefit_applications_of_sponsorships.each(&:recalc_pricing_determinations)
    puts("Finished recalculating prices of benefit applications.") unless Rails.env.test?
  end

  def migrate
    coverage_start_on = ENV['coverage_start_on'].to_s
    coverage_end_on = ENV['coverage_end_on'].to_s
    if [coverage_start_on, coverage_end_on].any?(&:blank?)
      raise("Please provide coverage start on and coverage end on (effective period) dates.") unless Rails.env.test?
      return
    else
      @coverage_start_on = Date.strptime(coverage_start_on, "%m/%d/%Y")
      @coverage_end_on = Date.strptime(coverage_end_on, "%m/%d/%Y")
    end
    puts('Executing migration') unless Rails.env.test?
    # TODO: Enhance code to get specific organizations (working from an existing database)
    employer_legal_name_list
    target_organziations
    benefit_sponsorships_of_organizations
    benefit_applications_of_sponsorships
    update_dates_of_benefit_applications
    recalc_prices_of_benefit_applications
  end
end