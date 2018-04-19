#rake migrate:hbx_profiles site_key=dc

require 'csv'

namespace :migrate do
  desc "migrate hbx profile and organization"
  task :hbx_profiles => :environment do
    site_key = ENV['site_key']

    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/hbx_profile_migration_status#{TimeKeeper.datetime_of_record.strftime("%m_%d_%Y_%H_%M_%S")}.csv"
    field_names = %w( organization_id hbx_id status)

    @logger = Logger.new("#{Rails.root}/log/hbx_profile_migration.log")
    @logger.info "Script Start #{TimeKeeper.datetime_of_record}"

    CSV.open(file_name, 'w') do |csv|
      csv << field_names

      @site = find_site(site_key)

      #build and create ExemptOrganization and its profile
      status = create_hbx_profile(csv)
      if status
        puts "Rake Task execution completed, check hbx_profile_migration logs & hbx_profile_migration_status csv for additional information." unless Rails.env.test?
      else
        @logger.info "Check if the inputed ENV values are valid" unless Rails.env.test?
        puts "Rake Task execution failed for given input" unless Rails.env.test?
      end
      @logger.info "End of the script" unless Rails.env.test?
    end
  end
end

def create_hbx_profile(csv)
  #site has one owner and one HBX profile
  # if !@site.owner_organization.present?

  @old_organization = Organization.unscoped.exists(hbx_profile: true).first
  return false unless @old_organization.present?
  existing_organization = 0
  begin
    if existing_general_organization.count == 0
      @old_profile = @old_organization.hbx_profile

      json_data = @old_profile.to_json(:except => [:_id, :hbx_staff_roles, :updated_by_id, :enrollment_periods, :benefit_sponsorship, :inbox, :documents])
      old_profile_params = JSON.parse(json_data)
      @new_profile = initialize_new_profile(old_profile_params)

      exempt_organization = initialize_exempt_organization
      exempt_organization.save!
      # @site.owner_organization = exempt_organization

      csv << [@old_organization.id, @old_organization.hbx_id, "success"]
    else
      existing_organization = existing_organization + 1
      csv << [@old_organization.id, @old_organization.hbx_id, "Already Migrated to new model, no action taken"]
    end

  rescue Exception => e
    csv << [@old_organization.id, @old_organization.hbx_id, "Migration Failed"]
    @logger.error "Migration Failed for Organization HBX_ID: #{@old_organization.hbx_id} , #{e.inspect}" unless Rails.env.test?
  end
  # end
  return true
end

def existing_general_organization
  BenefitSponsors::Organizations::ExemptOrganization.where(legal_name: @old_organization.legal_name)
end

def initialize_new_profile(old_profile_params)
  new_profile = BenefitSponsors::Organizations::HbxProfile.new(old_profile_params)

  build_inbox_messages(new_profile)
  build_documents
  build_office_locations(new_profile)

  return new_profile
end

def build_inbox_messages(new_profile)
  @old_profile.inbox.messages.each do |message|
    new_profile.inbox.messages.new(message.attributes.except("_id"))
  end
end

def build_documents
  @old_organization.documents.each do |document|
    new_profile.documents.new(document.attributes.except("_id"))
  end
end

def build_office_locations(new_profile)
  @old_organization.office_locations.each do |office_location|
    new_office_location = new_profile.office_locations.new()
    new_office_location.is_primary = office_location.is_primary
    address_params = office_location.address.attributes.except("_id")
    phone_params = office_location.phone.attributes.except("_id")
    new_office_location.address = address_params
    new_office_location.phone = phone_params
  end
end

def initialize_exempt_organization
  json_data = @old_organization.to_json(:except => [:_id, :updated_by_id, :hbx_profile, :office_locations, :version, :updated_by, :is_fake_fein, :is_active])
  org_params = JSON.parse(json_data)
  exempt_organization = BenefitSponsors::Organizations::ExemptOrganization.new(org_params)
  exempt_organization.site = @site
  exempt_organization.profiles << [@new_profile]
  return exempt_organization
end

def find_site(site_key)
  sites = BenefitSponsors::Site.all.where(site_key: site_key.to_sym)
  sites.present? ? sites.first : false
end