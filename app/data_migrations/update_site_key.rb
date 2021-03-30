require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateSiteKey < MongoidMigrationTask
  def migrate
    site_key = ENV['new_site_key'].to_sym
    BenefitSponsors::Site.all.first.update!(site_key: site_key)
  rescue Exception => e
    puts e.message
  end
end
