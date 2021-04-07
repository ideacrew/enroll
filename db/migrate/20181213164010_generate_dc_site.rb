class GenerateDcSite < Mongoid::Migration
  def self.up
    say_with_time("Creating Site") do
      @site = BenefitSponsors::Site.new(
          site_key: EnrollRegistry[:enroll_app].setting(:site_key).item,
          byline: EnrollRegistry[:enroll_app].setting(:byline).item,
          short_name: EnrollRegistry[:enroll_app].setting(:short_name).item,
          domain_name: EnrollRegistry[:enroll_app].setting(:domain_name).item,
          long_name: EnrollRegistry[:enroll_app].setting(:long_name).item)
      # TODO check on domain_name & long_name

      @old_org = Organization.unscoped.exists(hbx_profile: true).first
      @old_profile = @old_org.hbx_profile

      new_profile = initialize_hbx_profile
      owner_organization = initialize_exempt_organization(new_profile)
      owner_organization.save!

      update_hbx_staff_roles(new_profile) # updates person hbx_staff_role with new profile id
      @site.owner_organization = owner_organization
    end

    say_with_time("Creating ACA SHOP Benefit Market") do
      if EnrollRegistry.feature_enabled?(:aca_shop_market) 
        inital_app_config = BenefitMarkets::Configurations::AcaShopInitialApplicationConfiguration.new
        renweal_app_config = BenefitMarkets::Configurations::AcaShopRenewalApplicationConfiguration.new
        configuration = BenefitMarkets::Configurations::AcaShopConfiguration.new initial_application_configuration: inital_app_config,
                                                                                 renewal_application_configuration: renweal_app_config,
                                                                                 binder_due_dom: 12
        @benefit_market = BenefitMarkets::BenefitMarket.new kind: :aca_shop,
                                                            site_urn: EnrollRegistry[:enroll_app].setting(:site_key).item,
                                                            title: 'ACA SHOP',
                                                            description: "#{EnrollRegistry[:enroll_app].setting(:site_key).item} ACA Shop Market",
                                                            configuration: configuration

        # TODO Need to verify whether to create new configuartion for congress (or) use shop configuration
        @congress_benefit_market = BenefitMarkets::BenefitMarket.new kind: :fehb,
                                                            site_urn: EnrollRegistry[:enroll_app].setting(:site_key).item,
                                                            title: 'ACA SHOP',
                                                            description: "#{EnrollRegistry[:enroll_app].setting(:site_key).item} ACA Shop Market",
                                                            configuration: configuration
      end
    end

      @site.benefit_markets = [@benefit_market, @congress_benefit_market]

      # TODO ivl benefit_market

      if @site.valid?
        @site.save!
      else
        puts @site.configuration.errors.full_messages.inspect
      end

      if @benefit_market.valid?
        @benefit_market.site = @site
        @benefit_market.save!
      else
        puts @benefit_market.configuration.errors.full_messages.inspect
      end

      if @congress_benefit_market.valid?
        @congress_benefit_market.site = @site
        @congress_benefit_market.save!
      else
        puts @congress_benefit_market.configuration.errors.full_messages.inspect
      end
    else
      say "Skipping for SHOP site"
    end
  end

  def self.down
    ::BenefitSponsors::Organizations::Organization.hbx_profiles.delete_all
    ::BenefitSponsors::Site.where(site_key: EnrollRegistry[:enroll_app].setting(:site_key).item).delete_all
    ::BenefitMarkets::BenefitMarket.all.delete_all
  end

  def self.sanitize_hbx_params
    # TODO check for benefit_sponsorship with IVL team
    json_data = @old_profile.to_json(:except => [:_id, :hbx_staff_roles, :updated_by_id, :enrollment_periods, :benefit_sponsorship, :inbox, :documents])
    JSON.parse(json_data)
  end

  def self.initialize_hbx_profile
    profile = BenefitSponsors::Organizations::HbxProfile.new(self.sanitize_hbx_params)
    build_inbox_messages(profile)
    build_documents(profile)
    build_office_locations(profile)
    profile
  end

  def self.build_inbox_messages(new_profile)
    @old_profile.inbox.messages.each do |message|
      new_profile.inbox.messages.new(message.attributes.except("_id"))
    end
  end

  def self.build_documents(new_profile)
    @old_org.documents.each do |document|
      new_profile.documents.new(document.attributes.except("_id"))
    end
  end

  def self.build_office_locations(new_profile)
    @old_org.office_locations.each do |office_location|
      new_office_location = new_profile.office_locations.new()
      new_office_location.is_primary = office_location.is_primary
      address_params = office_location.address.attributes.except("_id")
      phone_params = office_location.phone.attributes.except("_id")
      new_office_location.address = address_params
      new_office_location.phone = phone_params
    end
  end

  def self.initialize_exempt_organization(new_profile)
    json_data = @old_org.to_json(:except => [:_id, :updated_by_id, :hbx_profile, :issuer_assigned_id,:office_locations, :version, :updated_by, :is_fake_fein, :is_active])
    exempt_organization = BenefitSponsors::Organizations::ExemptOrganization.new(JSON.parse(json_data))
    exempt_organization.site = @site
    exempt_organization.profiles << [new_profile]
    exempt_organization
  end

  def self.update_hbx_staff_roles(new_profile)
    Person.where(:'hbx_staff_role'.exists=>true).each do |person|
      person.hbx_staff_role.benefit_sponsor_hbx_profile_id = new_profile.id
      if person.valid? #TODO verify validation failed person
        person.save!
      else
        person.save!(validate: false)
        puts "validation failed for person hbx_id: #{person.hbx_id}"
      end
    end
  end
end