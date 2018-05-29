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


        old_org.employer_profile.plan_years.each do |plan_year|

          benefit_sponsorship = find_or_create_benefit_sponsorship(new_organization, plan_year)
          create_benefit_application(benefit_sponsorship, plan_year)


        # create_benefit_sponsorship(org) unless org.benefit_sponsorships.present? # create benefit sponsorship if not present
        # has_continuous_coverage_previously?(old_org)
        # old_org.employer_profile.plan_years.each do |py|
        #   benefit_sponsorship = new_organization.benefit_sponsorships.detect{ |bs| (bs.effective_begin_on..bs.effective_end_on).cover?(py.start_on) }
        #   initialize_benefit_application(benefit_sponsorship, params)
        #   benefit_application = initialize_benefit_application(sanitize_params(params))
        #   benefit_sponsorship.benefit_applications << benefit_application
        #   benefit_sponsorship.save!
        # end



      end
    end
  end

  def find_or_create_benefit_sponsorship(new_organization, plan_year)
    benefit_sponsorship = new_organization.benefit_sponsorships.detect{ |bs| (bs.effective_begin_on..bs.effective_end_on).cover?(py.start_on) } 
  end

  def create_benefit_application(benefit_sponsorship, plan_year)

    benefit_application = construct_benefit_application(benefit_sponsorship, plan_year)
    
    @benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(benefit_application.effective_period.min)
    benefit_application.benefit_sponsor_catalog = @benefit_sponsor_catalog

    plan_year.benefit_groups.each do |benefit_group|
      construct_benefit_package(benefit_application, benefit_group)
      benefit_application.benefit_packages.build(benefit_package_params)
    end

    @benefit_sponsor_catalog =  nil
    benefit_application.save
  end

  def effective_period_for(plan_year)
    plan_year.start_on..plan_year.end_on
  end

  def open_enrollment_period_for(plan_year)
    plan_year.open_enrollment_start_on..plan_year.open_enrollment_end_on
  end

  def  construct_benefit_application(benefit_sponsorship, plan_year)
    py_attrs = plan_year.attributes.except(:benefit_groups, :workflow_state_transitions)
    application_attrs = py_attrs.slice(:fte_count, :pte_count, :msp_count, :enrolled_summary, :waived_summary, :created_at, :updated_at, :terminated_on)

    benefit_application = benefit_sponsorship.benefit_applications.new(application_attrs)
    benefit_application.effective_period = effective_period_for(plan_year)
    benefit_application.open_enrollment_period = open_enrollment_period_for(plan_year)

    # "aasm_state"=>"active",
    # "imported_plan_year"=>false,
    # "is_conversion"=>false,
    # "updated_by_id"=>BSON::ObjectId('5909e07d082e766d68000078'),
  end

  def construct_benefit_package(benefit_application, benefit_group)
    benefit_package = benefit_application.benefit_packages.build

    if health_offering_available
      attrs[:product_kind] = :health
      construct_sponsored_benefit(benefit_package, attrs)
    end

    if dental_offering_available
      attrs[:product_kind] = :dental
      construct_sponsored_benefit(benefit_package, attrs)
    end
  end

  def construct_sponsored_benefit(benefit_package, attrs)
    sponsored_benefit  = benefit_package.sponsored_benefits.build
    construct_sponsor_contribution(sponsored_benefit, contribution_attrs)
  end

  def product_package_for(product_kind, package_kind)
    @benefit_sponsor_catalog.product_packages
  end

  def construct_sponsor_contribution(sponsored_benefit, attrs)
    new_product_package = @benefit_sponsor_catalog.product_package_for(sponsored_benefit)

    new_sponsor_contribution = BenefitSponsors::SponsoredBenefits::SponsorContribution.sponsor_contribution_for(new_product_package)
    new_sponsor_contribution.contribution_levels.each do |new_contribution_level|

      current_contribution_level = contribution_levels.detect{|cl| cl.display_name == new_contribution_level.display_name}
      if current_contribution_level.present?
        new_contribution_level.is_offered = current_contribution_level.is_offered
        new_contribution_level.contribution_factor = current_contribution_level.contribution_factor
      end
    end
  end

  def construct_pricing_determination

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