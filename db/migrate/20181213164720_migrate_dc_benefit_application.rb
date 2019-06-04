class MigrateDcBenefitApplication < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "dc"

      @logger = Logger.new("#{Rails.root}/log/benefit_application_migration.log")
      @logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?

      migrate_plan_years_to_benefit_applications

      @logger.info "End of the script" unless Rails.env.test?
    else
      say "Skipping for non-CCA site"
    end
  end

  def self.down
  end

  def self.migrate_plan_years_to_benefit_applications

    old_organizations = Organization.unscoped.exists(:"employer_profile.plan_years" => true)

    success = 0
    failed = 0
    total_plan_years = 0
    limit = 1000

    say_with_time("Time take to migrate plan years") do
      old_organizations.batch_size(limit).no_timeout.each do |old_org|

        raise StandardError, "New Organization not found" unless new_org(old_org).present?

        new_organization = new_org(old_org)

        benefit_sponsorship = new_organization.first.active_benefit_sponsorship
        set_benefit_sponsorship_state(old_org, benefit_sponsorship)
        benefit_sponsorship.registered_on = old_org.employer_profile.registered_on
        benefit_sponsorship.effective_begin_on = self.get_benefit_sponsorship_effective_on(old_org)
        construct_workflow_state_for_benefit_sponsorship(benefit_sponsorship, old_org)
        BenefitSponsors::BenefitSponsorships::BenefitSponsorship.skip_callback(:save, :after, :notify_on_save, raise: false)
        benefit_sponsorship.save

        # BenefitSponsors::BenefitSponsorships::BenefitSponsorship.set_callback(:save, :after, :notify_on_save)

        old_org.employer_profile.plan_years.asc(:start_on).each do |plan_year|
          total_plan_years += 1
          @benefit_package_map = {}
          begin
            benefit_application = convert_plan_year_to_benefit_application(benefit_sponsorship, plan_year)
            if benefit_application.valid?
              BenefitSponsors::BenefitApplications::BenefitApplication.skip_callback(:save, :after, :notify_on_save,  raise: false)
              benefit_application.save!
              assign_employee_benefits(benefit_sponsorship)
             # BenefitSponsors::BenefitApplications::BenefitApplication.set_callback(:save, :after, :notify_on_save,  raise: false)
              print '.' unless Rails.env.test?
              success += 1
            else
              raise StandardError, benefit_application.errors.to_s
            end
          rescue Exception => e
            failed = failed + 1
            print 'F' unless Rails.env.test?
            @logger.error "Migration Failed for Organization HBX_ID: #{old_org.hbx_id},
            validation_errors:
            benefit_application - #{benefit_application.try(:errors).try(:messages)},
            #{e.inspect}" unless Rails.env.test?
          end
        end
      end
      @logger.info " Total #{old_organizations.count} old organizations with plan years" unless Rails.env.test?
      @logger.info " Total #{total_plan_years} plan years" unless Rails.env.test?
      @logger.info " #{failed} plan years failed to migrate into new DB at this point." unless Rails.env.test?
      @logger.info " #{success} plan years successfully migrated into new DB at this point." unless Rails.env.test?
    end
  end

  # TODO: Verify updated by field on plan year updated_by_id
  def self.convert_plan_year_to_benefit_application(benefit_sponsorship, plan_year)
    py_attrs = plan_year.attributes.except(:benefit_groups, :workflow_state_transitions)
    application_attrs = py_attrs.slice(:fte_count, :pte_count, :msp_count, :created_at, :updated_at, :terminated_on)

    benefit_application = benefit_sponsorship.benefit_applications.new(application_attrs)
    benefit_application.effective_period = (plan_year.start_on..plan_year.end_on)
    benefit_application.write_attribute(:effective_period, (plan_year.start_on..plan_year.end_on)) if plan_year.start_on == plan_year.end_on  # benefit_application.effective_period setter method setting value to nil if plan_year.start_on == plan_year.end_on for those cases uses below
    benefit_application.open_enrollment_period = (plan_year.open_enrollment_start_on..plan_year.open_enrollment_end_on)
    benefit_application.pull_benefit_sponsorship_attributes

    predecessor_application = benefit_sponsorship.benefit_applications.where(:"effective_period.max" => benefit_application.effective_period.min.to_date.prev_day, :aasm_state.in => [:active, :terminated, :expired, :imported])
    if predecessor_application.present?
      if predecessor_application.count < 2
        benefit_application.predecessor_id = predecessor_application.first.id
      else
        @logger.error "Found More than One Predecessor Application for #{plan_year.employer_profile.hbx_id}"
      end
    end

    if plan_year.start_on > Date.new(2018, 6,1) # TODO benefit sponsor catalog
      # @benefit_sponsor_catalog = duplicate_benefit_catalog(benefit_application)
      catalog = BenefitMarkets::BenefitSponsorCatalog.find_by(effective_date: benefit_application.start_on)
      raise Standard, "BenefitSponsorCatalog not found" if catalog.blank?
      @benefit_sponsor_catalog = catalog.deep_dup
      @benefit_sponsor_catalog._id = BSON::ObjectId.new
      @benefit_sponsor_catalog.product_packages.map {|pt| pt._id = BSON::ObjectId.new}
      @benefit_sponsor_catalog.new_record = true
      @benefit_sponsor_catalog.benefit_application_id = benefit_application.id
      @benefit_sponsor_catalog.save(validate: false)
    else
      @benefit_sponsor_catalog = BenefitMarkets::BenefitSponsorCatalog.find_by(effective_date: benefit_application.start_on) rescue nil
      raise Standard, "BenefitSponsorCatalog not found" if @benefit_sponsor_catalog.blank?
    end

    benefit_application.benefit_sponsor_catalog_id = @benefit_sponsor_catalog.id

    # TODO: do unscoped...to pick all the benefit groups
    plan_year.benefit_groups.unscoped.each do |benefit_group|
      params = sanitize_benefit_group_attrs(benefit_group)
      importer = BenefitSponsors::Importers::BenefitPackageImporter.call(benefit_application, params)
      if importer.benefit_package.blank?
        raise Standard, "Benefit Package creation failed"
      end
      @benefit_package_map[benefit_group] = importer.benefit_package
      # TODO FIX method benefit package predecessor
      # self.set_predecessor_for_benefit_package(benefit_application, importer.benefit_package)
    end

    set_plan_year_aasm_state(benefit_application, plan_year)
    construct_workflow_state_transitions(benefit_application, plan_year)
    benefit_application
  end

  def self.set_plan_year_aasm_state(benefit_application, plan_year)
    benefit_application.aasm_state = benefit_application.matching_state_for(plan_year)
    if benefit_application.aasm_state == :binder_paid && plan_year.employer_profile.aasm_state.to_sym != :binder_paid
      benefit_application.aasm_state = :enrollment_closed
    elsif plan_year.is_conversion
      benefit_application.aasm_state = :imported
    end
  end

  def self.benefit_sponsor_catalog_hash
   return @catalog_hash if @catalog_hash.present?
   # Rails.cache.fetch("", expires_in: 2.hour) do
      @catalog_hash = {}
       BenefitSponsors::Site.all.first.benefit_markets[0].benefit_market_catalogs.each do |benefit_catalog|
         service_areas = ::BenefitMarkets::Locations::ServiceArea.where("active_year" => benefit_catalog.product_active_year).to_a
         (1..12).each do |i|
           effective_date = Date.new(benefit_catalog.product_active_year, i, 1)
           if Organization.where(:'employer_profile.plan_years.start_on'=> effective_date).present?
             catalog = BenefitMarkets::BenefitSponsorCatalogFactory.call(effective_date, benefit_catalog, service_areas)
             @catalog_hash[effective_date] = catalog.as_document
           end
         end
       end
      BenefitMarkets::BenefitSponsorCatalog.collection.insert_many(@catalog_hash.values)
   # end
  end

  def self.duplicate_benefit_catalog(benefit_application)
    json_object =  benefit_sponsor_catalog_hash[benefit_application.effective_period.min.to_date]
    new_json = json_object.dup
    new_json["_id"] = BSON::ObjectId.new
    new_json["product_packages"] = new_json["product_packages"].map do |p_package|
      new_pp = p_package.dup
      new_pp["_id"]= BSON::ObjectId.new
      new_pp
    end
    BenefitMarkets::BenefitSponsorCatalog.collection.insert_one(new_json)
    BenefitMarkets::BenefitSponsorCatalog.find(new_json["_id"])
  end

  def self.get_benefit_sponsorship_effective_on(old_org)
    plan_years = old_org.employer_profile.plan_years.asc(:start_on).where(:aasm_state.in=> [:active, :terminated, :expired])
    if plan_years.present?
      plan_years.first.start_on
    else
      return nil
    end
  end

  def self.set_predecessor_for_benefit_package(benefit_application, benefit_package)
    return unless benefit_application.predecessor_id.present?
    predecessor_application = benefit_application.predecessor
    predecessor_benefit_packages = benefit_application.predecessor.benefit_packages

    if predecessor_benefit_packages.count < 2
      benefit_package.predecessor_id  = benefit_application.predecessor.benefit_packages.first.id
      return
    end
    new_package_hios_id = benefit_package.health_sponsored_benefit.products(benefit_application.effective_period.min).map(&:hios_id)
    predecessor_benefit_packages.each do |predecessor_package|
      predecessor_package_hios_id = predecessor_package.health_sponsored_benefit.products(predecessor_application.effective_period.min).map(&:hios_id)
      if ((new_package_hios_id.size == predecessor_package_hios_id.size) && ((new_package_hios_id && predecessor_package_hios_id).size == new_package_hios_id.size))
        benefit_package.predecessor_id  = predecessor_package.id
      end
    end
  end

  def self.sanitize_benefit_group_attrs(benefit_group)
    attributes = benefit_group.attributes.slice(
        :title, :description, :created_at, :updated_at, :is_active, :effective_on_kind, :effective_on_offset,
        :plan_option_kind, :relationship_benefits, :dental_relationship_benefits
    )

    attributes[:is_default] = benefit_group.default
    attributes[:reference_plan_hios_id] = benefit_group.reference_plan.hios_id
    if benefit_group.is_offering_dental?
      attributes[:dental_reference_plan_hios_id] = benefit_group.dental_reference_plan.hios_id
      attributes[:dental_plan_option_kind] = benefit_group.dental_plan_option_kind
      attributes[:elected_dental_plan_hios_ids] = benefit_group.elected_dental_plans.map(&:hios_id)
    end
    attributes.symbolize_keys
  end

  def self.construct_workflow_state_transitions(benefit_application, plan_year)
    plan_year.workflow_state_transitions.unscoped.asc(:transition_at).each do |wst|
      attributes = wst.attributes.except(:_id)
      attributes[:from_state] = benefit_application.send(:plan_year_to_benefit_application_states_map)[wst.from_state.to_sym]
      attributes[:to_state] = benefit_application.send(:plan_year_to_benefit_application_states_map)[wst.to_state.to_sym]
      attributes[:to_state] = :enrollment_closed if attributes[:to_state] == :binder_paid && !([:enrolled, :binder_paid].include?(plan_year.employer_profile.aasm_state.to_sym))
      benefit_application.workflow_state_transitions.build(attributes)
    end
  end

  def self.set_benefit_sponsorship_state(old_org, benefit_sponsorship)

    if ["conversion", "mid_plan_year_conversion"].include?(benefit_sponsorship.source_kind.to_s)
      benefit_sponsorship.aasm_state = :active
      return
    end

    if benefit_sponsorship.source_kind.to_s == "self_serve"

      if old_org.employer_profile.active_plan_year.present?
        benefit_sponsorship.aasm_state = :active
        return
      end

      if old_org.employer_profile.published_plan_year.present? && old_org.employer_profile.published_plan_year.enrolling?
        benefit_sponsorship.aasm_state = :applicant
      else
        benefit_sponsorship.aasm_state = benefit_sponsorship.send(:employer_profile_to_benefit_sponsor_states_map)[old_org.employer_profile.aasm_state.to_sym]
      end
    end
  end

  def self.construct_workflow_state_for_benefit_sponsorship(benefit_sponsorship, old_org)
    old_org.employer_profile.workflow_state_transitions.unscoped.asc(:transition_at).each do |wst|
      attributes = wst.attributes.except(:_id)
      attributes[:from_state] = benefit_sponsorship.send(:employer_profile_to_benefit_sponsor_states_map)[wst.from_state.to_sym]
      attributes[:to_state] = benefit_sponsorship.send(:employer_profile_to_benefit_sponsor_states_map)[wst.to_state.to_sym]
      benefit_sponsorship.workflow_state_transitions.build(attributes)
    end
  end

  def self.assign_employee_benefits(benefit_sponsorship)
    @benefit_package_map.each do |benefit_group, benefit_package|
      benefit_group.census_employees.unscoped.each do |census_employee|
        if census_employee.benefit_sponsorship_id.blank?
          census_employee.employee_role.update_attributes(benefit_sponsors_employer_profile_id: benefit_sponsorship.organization.employer_profile.id) if census_employee.employee_role && census_employee.employee_role.benefit_sponsors_employer_profile_id.blank?
          census_employee.benefit_sponsors_employer_profile_id = benefit_sponsorship.organization.employer_profile.id if census_employee.benefit_sponsors_employer_profile_id.blank?
          census_employee.benefit_sponsorship = benefit_sponsorship
        end

        census_employee.benefit_group_assignments.unscoped.where(benefit_group_id: benefit_group.id).update_all(benefit_package_id:  benefit_package.id)

        CensusEmployee.skip_callback(:save, :after, :assign_default_benefit_package,  raise: false)
        CensusEmployee.skip_callback(:save, :after, :assign_benefit_packages,  raise: false)
        CensusEmployee.skip_callback(:save, :after, :construct_employee_role,  raise: false)
        CensusEmployee.skip_callback(:update, :after, :update_hbx_enrollment_effective_on_by_hired_on,  raise: false)
        census_employee.save(:validate => false)
        # CensusEmployee.set_callback(:save, :after, :assign_default_benefit_package,  raise: false)
        # CensusEmployee.set_callback(:save, :after, :assign_benefit_packages,  raise: false)
        # CensusEmployee.set_callback(:save, :after, :construct_employee_role,  raise: false)
        # CensusEmployee.set_callback(:update, :after, :update_hbx_enrollment_effective_on_by_hired_on,  raise: false)
      end
    end
  end

  def self.new_org(old_org)
    BenefitSponsors::Organizations::Organization.where(hbx_id: old_org.hbx_id)
  end
end