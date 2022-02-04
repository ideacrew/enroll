# desc "Explaining what the task does"
# task :benefit_sponsors do
#   # Task goes here
# end
def initialize_site
  p "Creating base site..."
  site = BenefitSponsors::Site.new.tap do |s|
    s.site_key = EnrollRegistry[:enroll_app].setting(:site_key).item
    s.long_name = EnrollRegistry[:enroll_app].setting(:long_name).item
    s.short_name = EnrollRegistry[:enroll_app].setting(:short_name).item
    s.byline = EnrollRegistry[:enroll_app].setting(:byline).item
    s.domain_name = EnrollRegistry[:enroll_app].setting(:domain_name).item
    s.home_url = EnrollRegistry[:enroll_app].setting(:home_url).item
    s.help_url = EnrollRegistry[:enroll_app].setting(:help_url).item
    s.faqs_url = Settings.site.faq_url
    s.logo_file_name = EnrollRegistry[:enroll_app].setting(:logo_file_name).item
  end

  p "Creating HBX parent organization..."
  owner_org = BenefitSponsors::Organizations::ExemptOrganization.new.tap do |org|
    org.home_page = EnrollRegistry[:enroll_app].setting(:home_url).item
    org.legal_name = EnrollRegistry[:enroll_app].setting(:long_name).item
    org.dba = "12345"
    org.entity_kind = :health_insurance_exchange
    org.profiles << BenefitSponsors::Organizations::HbxProfile.new(cms_id: "12345", us_state_abbreviation: Settings.aca.state_abbreviation)
  end

  owner_org.site = site
  owner_org.save!

  site.owner_organization = owner_org
  site.save!
  p "Site created successfully!"
end

desc "Initialize Site model"
namespace :benefit_sponsors do
  task :initialize_site => :environment do
    if BenefitSponsors::Site.all.count == 0
      p "No Sites exist... creating default"
      initialize_site
    else
      p "A site has already been defined run 'rake benefit_sponsors:overwrite_site' to replace any existing sites"
    end
  end

  task :overwrite_site => :environment do
    p "Destroying existing sites..."
    BenefitSponsors::Site.destroy_all
    initialize_site
  end
end
