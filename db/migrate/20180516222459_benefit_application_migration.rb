class BenefitApplicationMigration < Mongoid::Migration

  def self.up
    # site_key = "dc"
    # Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    # file_name = "#{Rails.root}/hbx_report/benefit_application_status#{TimeKeeper.datetime_of_record.strftime("%m_%d_%Y_%H_%M_%S")}.csv"
    # field_names = %w( organization_id benefit_sponsor_organization_id status)
    # logger = Logger.new("#{Rails.root}/log/benefit_application_migration.log")
    # logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?
    # CSV.open(file_name, 'w') do |csv|
    #   csv << field_names
    #   status = create_benefit_application(site_key, csv, logger)
    #   if status
    #     puts "Check the report and logs for futher information"
    #   else
    #     puts "Data migration failed"
    #   end
    # end
  end

  def self.down
  end

  private

  def create_benefit_application(site_key, csv, logger)
    sites = find_site(site_key)
    return false unless sites.present?
    site = sites.first
    @benefit_market = benefit_market
    say_with_time("Time taken to pull all old organizations with plan years") do
      old_organizations = Organization.unscoped.exists(:"employer_profile.plan_years" => true)
    end

    total_old_plan_years = old_organizations.map(&:employer_profile).map(&:plan_years).count
    new_benefit_applications = 0
    success = 0
    failed = 0
    limit = 1000

    say_with_time("Time take to migrate plan years") do
      old_organizations.batch_size(limit).no_timeout.each do |old_org|
        new_organization = new_org(old_org)
        next unless new_organization.present?
        create_benefit_sponsorship(org) unless org.benefit_sponsorships.present? # create benefit sponsorship if not present
        has_continuous_coverage_previously?(old_org)
        old_org.employer_profile.plan_years.each do |py|
          benefit_sponsorship = new_organization.benefit_sponsorships.detect{ |bs| (bs.effective_begin_on..bs.effective_end_on).cover?(py.start_on) }
          benefit_application = initialize_benefit_application(sanitize_params(params))
          benefit_sponsorship.benefit_applications << benefit_application
          benefit_sponsorship.save!
        end
      end
    end
  end

  def date_params(py)
    {
      "effective_period" => py.start_on..py.end_on,
      "open_enrollment_period" => py.open_enrollment_start_on..py.open_enrollment_end_on,
    }
  end

  def sanitize_params(py)
    json_data = py.to_json(:except => [:_id, :updated_by_id, :imported_plan_year, :is_conversion, :benefit_groups, :start_on, :end_on, :open_enrollment_start_on, :open_enrollment_end_on])
    params = JSON.parse(json_data)
    params.merge(date_params(py))
  end

  def new_org(old_org)
    BenefitSponsors::Organizations::Organization.where(fein: old_org.fein).present?
  end

  def benefit_market
    site.benefit_market_for(:aca_shop)
  end

  def self.find_site(site_key)
    BenefitSponsors::Site.all.where(site_key: site_key.to_sym)
  end

  # check if organization has continuous coverage
  def has_continuous_coverage_previously?(org)
    true
  end

  def create_benefit_sponsorship(org)
    benefit_sponsorship = org.benefit_sponsorships.build
    benefit_sponsorship.benefit_market = @benefit_market
    benefit_sponsorship.profile = org.employer_profile
    benefit_sponsorship.save!
  end

  def initialize_benefit_application(params)
    BenefitSponsors::BenefitApplications::BenefitApplication.new(params)
  end
end