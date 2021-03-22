# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')

require File.join(Rails.root, 'app/data_migrations/golden_seed_helper')

class GoldenSeedIndividual < MongoidMigrationTask
  include GoldenSeedHelper
  def migrate
    puts('Executing Golden Seed IVL migration migration.')
    ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_empty_benefit_market if site.blank?
    # What to do here? They don't seem to create products but they do in the cucumbers for shopping?
    create_and_return_service_area_and_product if ivl_products.blank?
    create_and_return_ivl_hbx_profile_and_sponsorship
    5.times do
      consumer_role = create_and_return_matched_consumer_record[:consumer_role]
      generate_and_return_hbx_enrollment(consumer_role)
    end
    puts("Golden Seed IVL migration complete. All consumer roles are:")
    people = Person.all.select { |person| person.consumer_role.present? }
    people.each { |person| puts(person.full_name) }
  end
end


