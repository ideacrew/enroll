# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')
require File.join(Rails.root, 'app/data_migrations/golden_seed_helper')

# This class will:
# 1) Create a site with HBX/profile and empty benefit market if the site is blank.
#    It should work for any client (DC, ME, MA), because the ::BenefitSponsors::SiteSpecHelpers files have
#    been refactored to accommodate those.
# 2) Create fully matched consumer records. Their names will appear in the rake output.
# 3) Create an HbxEnrollment for each of those consumers, with an existing random IVL product OR a create a new one
# Notes:
# A) After running this rake task, you should be able to log in to the environment as a super admin, go to the HbxAdmin
# section, click the "Families" tab, and click one of the consumers, and see their current selected coverage.
# B) This rake task is designed to be "non intrusive", meaning that it won't modify any existing data, and can also be
# ran from a blank database
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
class GoldenSeedIndividual < MongoidMigrationTask
  include GoldenSeedHelper

  attr_accessor :counter_number, :consumer_people_and_users

  def migrate
    puts('Executing Golden Seed IVL migration migration.') unless Rails.env.test?
    puts("Site present, using existing site.") if site.present? && !Rails.env.test?
    ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_empty_benefit_market if site.blank?
    # What to do here? They don't seem to create products but they do in the cucumbers for shopping?
    puts("IVL products present in database, will use existing ones to create HbxEnrollments.") if ivl_products.present? && !Rails.env.test?
    create_and_return_service_area_and_product if ivl_products.blank?
    create_and_return_ivl_hbx_profile_and_sponsorship
    @counter_number = 0
    @consumer_people_and_users = {}
    5.times do
      consumer = create_and_return_matched_consumer_record
      consumer_people_and_users[consumer[:primary_person].full_name] = consumer[:user]
      generate_and_return_hbx_enrollment(consumer[:consumer_role])
      ['domestic_partner', 'child'].each do |personal_relationship_kind|
        generate_and_return_dependent_records(consumer[:primary_person], personal_relationship_kind)
      end
      @counter_number += 1
    end
    puts("Site present for: #{BenefitSponsors::Site.all.map(&:site_key)}") if BenefitSponsors::Site.present? && !Rails.env.test?
    puts("Golden Seed IVL migration complete. All consumer roles are:") unless Rails.env.test?
    consumer_people_and_users.each do |person_full_name, user_record|
      puts(person_full_name.to_s) unless Rails.env.test?
      puts("With user #{user_record.email}") if user_record && !Rails.env.test?
    end
  end
end

# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity



