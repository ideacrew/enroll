# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# updating site key to required site
class UpdateSiteKey < MongoidMigrationTask
  def migrate
    site_key = ENV['new_site_key']&.to_sym
    if site_key.present?
      BenefitSponsors::Site.all.first.update!(site_key: site_key)
    else
      puts "No site key provided" unless Rails.env.test?
    end
  rescue StandardError => e
    puts e.message
  end
end