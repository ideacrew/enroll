class BenefitApplicationMigration < Mongoid::Migration

  def self.up
    # site_key = "dc"
    # Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    # file_name = "#{Rails.root}/hbx_report/benefit_application_status#{TimeKeeper.datetime_of_record.strftime("%m_%d_%Y_%H_%M_%S")}.csv"
    # field_names = %w(organization_name organization_fein plan_year_start_on status)
    # logger = Logger.new("#{Rails.root}/log/benefit_application_migration.log")
    # logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?
    # CSV.open(file_name, 'w') do |csv|
    #   csv << field_names
    #   status = migrate_plan_years_to_benefit_applications(site_key, csv, logger)
    #   if status
    #     puts "Check the report and logs for futher information"
    #   else
    #     puts "Data migration failed"
    #   end
    # end
  end

  def self.down
  end

  class BenefitSponsorshipMigrationService
    def self.fetch_sponsorship_for(new_organization, plan_year)
      self.new(new_organization, plan_year).benefit_sponsorship
    end

    def initialize(new_organization, plan_year)
      find_or_create_benefit_sponsorship(new_organization, plan_year)
    end

    def find_or_create_benefit_sponsorship(old_organization, new_organization, plan_year)
      @benefit_sponsorship = benefit_sponsorship_for(new_organization, plan_year.start_on)

      if @benefit_sponsorship.blank?
        create_new_benefit_sponsorship(new_organization, plan_year)
      end

      if is_plan_year_effectuated?(plan_year)
        if [:active, :suspended, :terminated, :ineligible].exclude?(@benefit_sponsorship.aasm_state)
          effectuate_benefit_sponsorship(plan_year)
        end

        if has_no_successor_plan_year?(plan_year)
          @benefit_sponsorship.terminate_enrollment(plan_year.terminated_on || plan_year.end_on)
        end
      end
    end

    def benefit_sponsorship_for(new_organization, plan_year_start)
      benefit_sponsorship = new_organization.benefit_sponsorships.desc(:effective_begin_on).effective_begin_on(plan_year_start).first

      if benefit_sponsorship && benefit_sponsorship.effective_end_on.present?
        (benefit_sponsorship.effective_end_on > plan_year_start) ? benefit_sponsorship : nil
      else
        benefit_sponsorship
      end
    end

    # Add proper state transitions to benefit sponsorship
    def effectuate_benefit_sponsorship(plan_year)
      @benefit_sponsorship
    end

    def create_new_benefit_sponsorship(new_organization, plan_year)
      @benefit_sponsorship
    end

    def is_plan_year_effectuated?(plan_year)
      %w(active suspended expired terminated termination_pending).include?(plan_year.aasm_state)
    end

    def has_no_successor_plan_year?(plan_year)
      other_plan_years = plan_year.employer_profile.plan_years

      if plan_year.end_on > TimeKeeper.datetime_of_record
        true
      else
        other_plan_years.any?{|py| py != plan_year && py.start_on == plan_year.end_on.next_day && is_a_effectuated_plan_year?(py) }
      end
    end

    def benefit_sponsorship
      @benefit_sponsorship
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
  end

  private

  def migrate_plan_years_to_benefit_applications(site_key, csv, logger)
    say_with_time("Time taken to pull all old organizations with plan years") do
      old_organizations = Organization.unscoped.exists(:"employer_profile.plan_years" => true)
    end

    success = 0
    failed  = 0
    limit   = 100

    say_with_time("Time take to migrate plan years") do
      old_organizations.batch_size(limit).no_timeout.each do |old_org|
        new_organization = new_org(old_org)
        next unless new_organization.present?

        old_org.employer_profile.plan_years.asc(:start_on).each do |plan_year|
          begin
            benefit_sponsorship = BenefitSponsorshipMigrationService.fetch_sponsorship_for(new_organization, plan_year)
            benefit_application = contruct_benefit_application(benefit_sponsorship, plan_year)

            if benefit_application.valid?
              benefit_application.save!
              csv << [old_org.legal_name, old_org.fein, plan_year.start_on, 'Success']
              success += 1
            else
              raise StandardError, benefit_application.errors.to_s
            end
          rescue Exception => e
            csv << [old_org.legal_name, old_org.fein, plan_year.start_on, 'Failed', e.to_s]
            failed += 1
          end
        end
      end

      logger.info " Total #{total_organizations} old organizations with plan years" unless Rails.env.test?
      logger.info " #{failed} plan years failed to migrate into new DB at this point." unless Rails.env.test?
      logger.info " #{success} plan years successfully migrated into new DB at this point." unless Rails.env.test?
    end
  end

  def construct_benefit_application(benefit_sponsorship, plan_year)
    benefit_application = construct_benefit_application(benefit_sponsorship, plan_year)

    py_attrs = plan_year.attributes.except(:benefit_groups, :workflow_state_transitions)
    application_attrs = py_attrs.slice(:fte_count, :pte_count, :msp_count, :enrolled_summary, :waived_summary, :created_at, :updated_at, :terminated_on)

    benefit_application = benefit_sponsorship.benefit_applications.new(application_attrs)
    benefit_application.effective_period = effective_period_for(plan_year)
    benefit_application.open_enrollment_period = open_enrollment_period_for(plan_year)

    # "aasm_state"=>"active",
    # "imported_plan_year"=>false,
    # "is_conversion"=>false,
    # "updated_by_id"=>BSON::ObjectId('5909e07d082e766d68000078'),

    @benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(benefit_application.effective_period.min)
    benefit_application.benefit_sponsor_catalog = @benefit_sponsor_catalog

    plan_year.benefit_groups.each do |benefit_group|
      construct_benefit_package(benefit_application, benefit_group)
    end

    benefit_application.aasm_state = benefit_application.matching_state_for(plan_year)
    @benefit_sponsor_catalog =  nil
    construct_workflow_state_transitions(benefit_application, plan_year)
    benefit_application
  end

  def effective_period_for(plan_year)
    plan_year.start_on..plan_year.end_on
  end

  def open_enrollment_period_for(plan_year)
    plan_year.open_enrollment_start_on..plan_year.open_enrollment_end_on
  end

  def probation_period_kind_for(benefit_group)
  end

  def construct_benefit_package(benefit_application, benefit_group)
    benefit_group_attrs = benefit_group.attributes.slice(:title, :description, :created_at, :updated_at, :is_active)
    benefit_group_attrs[:is_default] = benefit_group.default
    benefit_group_attrs[:probation_period_kind] = probation_period_kind_for(benefit_group)

    benefit_package = benefit_application.benefit_packages.build(benefit_group_attrs)

    sponsored_benefit_attrs = benefit_group.attributes.slice(:plan_option_kind, :reference_plan_id, :relationship_benefits)
    sponsored_benefit_attrs[:product_kind] = :health
    sponsored_benefit_attrs[:reference_plan_hios_id] = benefit_group.reference_plan.hios_id
    benefit_package.sponsored_benefits << construct_sponsored_benefit(benefit_package, sponsored_benefit_attrs)

    if benefit_group.is_offering_dental?
      sponsored_benefit_attrs = benefit_group.attributes.slice(:dental_reference_plan_id, :dental_relationship_benefits)
      sponsored_benefit_attrs[:product_kind] = :dental
      sponsored_benefit_attrs[:reference_plan_hios_id] = benefit_group.dental_reference_plan.hios_id
      benefit_package.sponsored_benefits << construct_sponsored_benefit(sponsored_benefit_attrs)
    end
  end

  def construct_sponsored_benefit(benefit_package, sponsored_benefit_attrs)
    if sponsored_benefit_attrs[:product_kind] == :health
      sponsored_benefit = BenefitSponsors::SponsoredBenefits::HealthSponsoredBenefit.new
      sponsored_benefit.product_package_kind = map_product_package_kind(sponsored_benefit_attrs[:plan_option_kind])
      contribution_attrs = {contributions: sponsored_benefit_attrs[:relationship_benefits]}
    elsif sponsored_benefit_attrs[:product_kind] == :dental
      sponsored_benefit = BenefitSponsors::SponsoredBenefits::DentalSponsoredBenefit.new
      contribution_attrs = {contributions: sponsored_benefit_attrs[:dental_relationship_benefits]}
    end

    product_package = @benefit_sponsor_catalog.product_package_for(sponsored_benefit)
    sponsored_benefit.reference_product = product_package.products.where(hios_id: sponsored_benefit_attrs[:reference_plan_hios_id]).first
    sponsored_benefit.product_package_choice = product_package_choice_for(sponsored_benefit)
    construct_sponsor_contribution(sponsored_benefit, product_package, contribution_attrs)
  end

  def construct_sponsor_contribution(sponsored_benefit, product_package, attrs)
    new_sponsor_contribution = BenefitSponsors::SponsoredBenefits::SponsorContribution.sponsor_contribution_for(product_package)
    new_sponsor_contribution.contribution_levels.each do |new_contribution_level|
      contribution_match = attrs[:contributions].detect{|contribution| contribution['relationship'] == new_contribution_level.name}

      if contribution_match.present?
        new_contribution_level.is_offered = contribution_match['offered']
        new_contribution_level.contribution_factor = (contribution_match['premium_pct'].to_f / 100)
      end
    end
  end

  def construct_pricing_determination
  end

  def construct_workflow_state_transitions(benefit_application, plan_year)
    plan_year.workflow_state_transitions.asc(:transition_at).each do |wst|
      benefit_application.workflow_state_transitions.build(wst.attributes.except(:_id))
    end
  end

  def map_product_package_kind(plan_option_kind)
    package_kind_mapping = {
      sole_source: :single_product,
      single_plan: :single_product,
      single_carrier: :single_issuer,
      metal_level: :metal_level
    }

    package_kind_mapping[plan_option_kind.to_sym]
  end

  def product_package_choice_for(sponsored_benefit)
    case sponsored_benefit.product_package_kind
    when :single_product, :single_issuer
      sponsored_benefit.reference_product.issuer_profile.legal_name
    when :metal_level
      sponsored_benefit.reference_product.metal_level_kind
    end
  end

  # Verify if there're any duplicate/fake feins
  def new_org(old_org)
    BenefitSponsors::Organizations::Organization.where(fein: old_org.fein).present?
  end
end