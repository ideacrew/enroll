#rake migrate:organizations site_key=dc profile_type=employer_profile profile_class=aca_shop_dc_employer_profile
#rake migrate:organizations site_key=dc profile_type=broker_agency_profile profile_class=broker_agency_profile

require 'csv'

namespace :migrate do
  desc "organizations, profiles & roles migration"
  task :organizations => :environment do
    site_key = ENV['site_key']
    profile_class = ENV['profile_class']
    profile_type = ENV['profile_type']

    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/organizations_migration_status.csv"
    field_names = %w( organization_id fein hbx_id status)

    # @logger = Logger.new("#{Rails.root}/log/data_set.log")
    # @logger.info "Script Start #{TimeKeeper.datetime_of_record}"

    CSV.open(file_name, 'w') do |csv|
      csv << field_names
      #find or build site
      @site = find_site(site_key)

      #build and create GeneralOrganization and its profiles
      create_profile1(profile_type, profile_class, csv)

      #TODO
      #link profiles accounts - link created new employer profiles with created new broker agenacy profiles
      # broker_agency_accounts - ******
      # general_agency_accounts - *****
      # employer_profile_account - needs research wheather DC/ MA have data to migrate
    end
  end
end

def create_profile1(profile_type, profile_class, csv)

  old_organizations= get_old_organizations(profile_type)
  old_organizations.batch_size(1000).no_timeout.all.each do |old_org|

    if existing_general_organization(old_org).count == 0
      new_profile = initialize_new_profile(profile_class).new()
      old_profile = get_old_profile(old_org, profile_type)
      new_profile.entity_kind = old_profile.entity_kind
      new_profile.office_locations << old_org.office_locations

      #TODO
      #inbox
      #Message
      #Documents
      #employee, census employee
      #general agency role

      if profile_type == "broker_agency_profile"
        if old_profile.market_kind == "shop"
          market_kind = "aca_shop"
        elsif old_profile.market_kind == "individual"
          market_kind = "aca_individual"
        else
          market_kind = "both"
        end
        new_profile.market_kind = market_kind.to_sym
      end

        general_organization = create_general_organization(old_org, old_profile, new_profile)
        general_organization.save!

      person_records_with_old_staff_roles = find_staff_roles(profile_type, old_profile)
        link_existing_staff_roles_to_new_profile(profile_type, new_profile, person_records_with_old_staff_roles, old_profile)

      csv << [old_org.id, old_org.fein, old_org.hbx_id, "success"]
    end
  end
end

def get_old_organizations(profile_type)
  if profile_type == 'employer_profile'
    Organization.all_employer_profiles
  elsif profile_type == 'broker_agency_profile'
    Organization.has_broker_agency_profile
  end
end

def existing_general_organization(old_org)
  BenefitSponsors::Organizations::GeneralOrganization.where(fein: old_org.fein)
end

def initialize_new_profile(profile_class)
  "BenefitSponsors::Organizations::#{profile_class.camelize}".constantize
end

def get_old_profile(old_org, profile_type)
  if profile_type == "employer_profile"
    old_org.employer_profile
  else
    profile_type == "broker_agency_profile"
    old_org.broker_agency_profile
  end
end

def create_general_organization(organization, old_profile, new_profile)
  general_organization = BenefitSponsors::Organizations::GeneralOrganization.new(
      :fein => organization.fein,
      :hbx_id => organization.hbx_id,
      :legal_name => organization.legal_name,
      :dba => organization.dba,
      :entity_kind => old_profile.entity_kind.to_sym,
      :site => @site,
      :profiles => [new_profile]
  )
  return general_organization
end

def find_staff_roles(profile_type, old_profile)
  if (profile_type == "employer_profile")
    Person.where(:employer_staff_roles => {
        '$elemMatch' => {employer_profile_id: old_profile.id}})
  elsif profile_type == "broker_agency_profile"
    Person.or({:"broker_role.broker_agency_profile_id" => old_profile.id},
              {:"broker_agency_staff_roles.broker_agency_profile_id" => old_profile.id})
  end

end

# PR this
def link_existing_staff_roles_to_new_profile(profile_type, new_profile, person_records_with_old_staff_roles, old_profile)
  person_records_with_old_staff_roles.each do |person|
    if (profile_type == "employer_profile")
      old_employer_staff_role = person.employer_staff_roles.where(employer_profile_id: old_profile.id).first
      old_employer_staff_role.update_attributes(benefit_sponsors_employer_profile_id: new_profile.id) if old_employer_staff_role.present?
    elsif profile_type == "broker_agency_profile"
      old_broker_role = person.broker_role
      old_broker_agency_role = person.broker_agency_staff_roles.where(broker_agency_profile_id: old_profile.id).first

      old_broker_role.update_attributes(benefit_sponsors_broker_agency_profile_id: new_profile.id)
      old_broker_agency_role.update_attributes(benefit_sponsors_broker_agency_profile_id: new_profile.id) if old_broker_agency_role.present?
    end
  end
end

def find_site(site_key)
  sites = BenefitSponsors::Site.all.where(site_key: site_key.to_sym)
  sites.present? ? sites.first : false
end

