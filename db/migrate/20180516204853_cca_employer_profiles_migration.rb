class CcaEmployerProfilesMigration < Mongoid::Migration
  def self.up
    logger = Logger.new("#{Rails.root}/log/employer_profiles_migration_data.log") unless Rails.env.test?
    logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?
    create_profile(logger)
    logger.info "End of the script" unless Rails.env.test?
  end

  def self.down
  end

  private

  def self.create_profile(logger)

    old_organizations = Organization.unscoped.exists(:employer_profile => true)

    #counters
    total_organizations = old_organizations.count
    existing_organization = 0
    success =0
    failed = 0
    limit_count = 1000

    say_with_time("Time taken to migrate organizations") do
      old_organizations.batch_size(limit_count).no_timeout.all.each do |old_org|
        begin
          existing_new_organizations = find_new_organization(old_org)
          if existing_new_organizations.count == 0
            @old_profile = old_org.employer_profile

            json_data = @old_profile.to_json(:except => [:_id,:xml_transmitted_timestamp, :entity_kind, :profile_source, :aasm_state, :registered_on, :contact_method, :employer_attestation, :broker_agency_accounts, :general_agency_accounts, :employer_profile_account, :plan_years, :updated_by_id, :workflow_state_transitions, :inbox, :documents])
            old_profile_params = JSON.parse(json_data)

            @new_profile = initialize_new_profile(old_org, old_profile_params)
            new_organization = initialize_new_organization(old_org, site)

            @benefit_sponsorship = @new_profile.add_benefit_sponsorship
            @benefit_sponsorship.source_kind = @old_profile.profile_source.to_sym

            raise Exception unless @benefit_sponsorship.valid?
            BenefitSponsors::BenefitSponsorships::BenefitSponsorship.skip_callback(:save, :after, :notify_on_save)
            @benefit_sponsorship.save!

            raise Exception unless new_organization.valid?
            BenefitSponsors::Organizations::Organization.skip_callback(:create, :after, :notify_on_create)
            BenefitSponsors::Organizations::Profile.skip_callback(:save, :after, :publish_profile_event)
            new_organization.save!

            #employer staff roles migration
            person_records_with_old_staff_roles = find_staff_roles
            link_existing_staff_roles_to_new_profile(person_records_with_old_staff_roles)

            #employee roles migration
            person_records_with_old_employee_roles = find_employee_roles
            link_existing_employee_roles_to_new_profile(person_records_with_old_employee_roles)

            #census employees migration
            census_employees_with_old_id = find_census_employees
            link_existing_census_employees_to_new_profile(census_employees_with_old_id)

            print '.' unless Rails.env.test?
            success = success + 1
          end
        rescue Exception => e
          failed = failed + 1
          print 'F' unless Rails.env.test?
          logger.error "Migration Failed for Organization HBX_ID: #{old_org.hbx_id},
          validation_errors:
          organization - #{new_organization.errors.messages}
          profile - #{@new_profile.errors.messages},
          benefit_sponsorship - #{@benefit_sponsorship.errors.messages},
          #{e.inspect}" unless Rails.env.test?
        end
      end
    end
    logger.info " Total #{total_organizations} old organizations for type: employer profile" unless Rails.env.test?
    logger.info " #{failed} organizations failed to migrated to new DB at this point." unless Rails.env.test?
    logger.info " #{success} organizations migrated to new DB at this point." unless Rails.env.test?
    logger.info " #{existing_organization} old organizations are already present in new DB." unless Rails.env.test?
    return true
  end

  def self.find_new_organization(old_org)
    BenefitSponsors::Organizations::Organization.where(fein: old_org.fein)
  end

  def self.initialize_new_profile(old_org, old_profile_params)
    new_profile = BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new(old_profile_params)

    if @old_profile.contact_method == "Only Electronic communications"
      new_profile.contact_method = :electronic_only
    elsif @old_profile.contact_method == "Paper and Electronic communications"
      new_profile.contact_method = :paper_and_electronic
    elsif @old_profile.contact_method == "Only Paper communication"
      new_profile.contact_method = :paper_only
    end

    build_documents(old_org, new_profile)
    build_inbox_messages(new_profile)
    build_office_locations(old_org, new_profile)
    return new_profile
  end


  def self.build_employer_attestation(obj)

    old_attestation_params = @old_profile.employer_attestation.attributes.except("_id", "employer_profile", "employer_attestation_documents", "workflow_state_transitions")

    new_employer_attestation  = obj.build_employer_attestation(old_attestation_params)

    old_workflow_state_trans = @old_profile.employer_attestation.workflow_state_transitions
    build_workflow_state_transition(old_workflow_state_trans ,new_employer_attestation)

    @old_profile.employer_attestation.employer_attestation_documents.each do |employer_attestation_document|
      old_attestation_doc_params = employer_attestation_document.attributes.except("_id", "workflow_state_transitions")
      new_emp_attest_doc = new_employer_attestation.employer_attestation_documents.new(old_attestation_doc_params)

      old_workflow_state_trans = employer_attestation_document.workflow_state_transitions
      build_workflow_state_transition(old_workflow_state_trans, new_emp_attest_doc)
    end
  end

  def self.build_workflow_state_transition(old_workflow_state_trans, new_obj)
    old_workflow_state_trans.each do |old_workflow_state_tran|
      old_attestation_doc_params = old_workflow_state_tran.attributes.except("_id", "transitional")
      new_obj.workflow_state_transitions.new(old_attestation_doc_params)
    end
  end

  def self.build_documents(old_org, new_profile)

    @old_profile.documents.each do |document|
      doc = new_profile.documents.new(document.attributes.except("_id", "_type", "identifier","size"))
      doc.identifier = document.identifier if document.identifier.present?
      BenefitSponsors::Documents::Document.skip_callback(:save, :after, :notify_on_save)
      doc.save!
    end

    old_org.documents.each do |document|
      doc = new_profile.documents.new(document.attributes.except("_id", "_type", "identifier","size"))
      doc.identifier = document.identifier if document.identifier.present?
      BenefitSponsors::Documents::Document.skip_callback(:save, :after, :notify_on_save)
      doc.save!
    end
  end

  def self.build_inbox_messages(new_profile)
    @old_profile.inbox.messages.each do |message|
      msg = new_profile.inbox.messages.new(message.attributes.except("_id"))
      msg.body.gsub!("EmployerProfile", "AcaShopCcaEmployerProfile")
      msg.body.gsub!(@old_profile.id.to_s, new_profile.id.to_s)

      new_profile.documents.where(subject: "notice").each do |doc|
        old_emp_docs = @old_profile.documents.where(identifier: doc.identifier)
        old_org_docs = @old_profile.organization.documents.where(identifier: doc.identifier)
        old_document_id = if old_emp_docs.present?
                            old_emp_docs.first.id.to_s
                          elsif old_org_docs.present?
                            old_org_docs.first.id.to_s
                          end
        msg.body.gsub!(old_document_id, doc.id.to_s) if (doc.id.to_s.present? && old_document_id.present?)
      end

    end
  end

  def self.build_office_locations(old_org, new_profile)
    old_org.office_locations.each do |office_location|
      new_office_location = new_profile.office_locations.new
      new_office_location.is_primary = office_location.is_primary
      address_params = office_location.address.attributes.except("_id") if office_location.address.present?
      phone_params = office_location.phone.attributes.except("_id") if office_location.phone.present?
      new_office_location.address = address_params
      new_office_location.phone = phone_params
    end
  end

  def self.initialize_new_organization(organization, site)
    json_data = organization.to_json(:except => [:_id, :updated_by_id, :issuer_assigned_id, :version, :versions, :employer_profile, :broker_agency_profile, :general_agency_profile, :carrier_profile, :hbx_profile, :office_locations, :is_fake_fein, :is_active, :updated_by, :documents])
    old_org_params = JSON.parse(json_data)
    general_organization = BenefitSponsors::Organizations::GeneralOrganization.new(old_org_params)
    general_organization.entity_kind = @old_profile.entity_kind.to_sym
    general_organization.site = site
    general_organization.profiles << [@new_profile]
    return general_organization
  end

  def self.find_staff_roles
    Person.where(:employer_staff_roles => {
                     '$elemMatch' => {employer_profile_id: @old_profile.id}})
  end

  def self.link_existing_staff_roles_to_new_profile(person_records_with_old_staff_roles)
    person_records_with_old_staff_roles.each do |person|
      person.employer_staff_roles.where(employer_profile_id: @old_profile.id).update_all(benefit_sponsor_employer_profile_id: @new_profile.id)
    end
  end

  def self.find_employee_roles
    Person.where(:"employee_roles.employer_profile_id" => @old_profile.id)
  end

  def self.link_existing_employee_roles_to_new_profile(person_records_with_old_employee_roles)
    person_records_with_old_employee_roles.each do |person|
      person.employee_roles.where(employer_profile_id: @old_profile.id).update_all(benefit_sponsors_employer_profile_id: @new_profile.id)
    end
  end

  def self.find_census_employees
    CensusEmployee.where(employer_profile_id: @old_profile.id)
  end

  def self.link_existing_census_employees_to_new_profile(census_employees_with_old_id)
    census_employees_with_old_id.update_all(benefit_sponsors_employer_profile_id: @new_profile.id, benefit_sponsorship_id: @benefit_sponsorship.id)
  end

  def self.find_site(site_key)
    BenefitSponsors::Site.all.where(site_key: site_key.to_sym)
  end
end
