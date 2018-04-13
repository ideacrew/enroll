#rake migrate:hbx_profiles site_key=dc

require 'csv'

namespace :migrate do
  desc "migrate hbx profile and organization"
  task :hbx_profiles => :environment do
    site_key = ENV['site_key']

    Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/organizations_migration_status.csv"
    field_names = %w( organization_id fein hbx_id status)

    # @logger = Logger.new("#{Rails.root}/log/data_set.log")
    # @logger.info "Script Start #{TimeKeeper.datetime_of_record}"

    CSV.open(file_name, 'w') do |csv|
      csv << field_names

      @site = find_site(site_key)

      #build and create ExemptOrganization and its profile
      create_hbx_profile(csv)

    end
  end
end


def create_hbx_profile(csv)

  #site has one owner and one HBX profile
  # if !@site.owner_organization.present?
  @old_organization = Organization.unscoped.exists(hbx_profile: true).first

  if existing_general_organization.count == 0
    @old_profile = old_organization.hbx_profile

    json_data = old_profile.to_json(:except => [:_id, :hbx_staff_roles, :enrollment_periods, :benefit_sponsorship, :inbox, :documents])
    old_profile_params = JSON.parse(json_data)
    @new_profile = initialize_new_profile(old_profile_params)

    #TODO
    #Documents -- currently new model has embed many documents from organizations,
    #but old model has embed many documents from organization and profiles

    exempt_organization = initialize_exempt_organization
    exempt_organization.save!
    # @site.owner_organization = exempt_organization

    csv << [@old_organization.id, @old_organization.fein, @old_organization.hbx_id, "success"]
  end
  # end
end

def existing_general_organization
  BenefitSponsors::Organizations::ExemptOrganization.where(legal_name: @old_organization.legal_name)
end

def initialize_new_profile(old_profile_params)
  new_profile = BenefitSponsors::Organizations::HbxProfile.new(old_profile_params)
  new_profile.inbox.messages << @old_profile.inbox.messages
  new_profile.office_locations << @old_organization.office_locations
  return new_profile
end

def initialize_exempt_organization
  json_data = @old_organization.to_json(:except => [:_id, :hbx_profile, :office_locations, :version, :updated_by, :is_fake_fein, :is_active])
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