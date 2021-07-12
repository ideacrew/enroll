# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class PopulateAssignedContributionModel < MongoidMigrationTask

  def migrate
    time = Date.new(2020,2,1).beginning_of_day
    site = BenefitSponsors::Site.by_site_key(EnrollRegistry[:enroll_app].setting(:site_key).item).first
    benefit_market = site.benefit_markets.where(kind: :aca_shop).first
    benefit_market_catalog = benefit_market.benefit_market_catalogs.by_application_date(time).first

    benefit_sponsorships = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:benefit_applications => {:$elemMatch => {:created_at.gte => time}})
    batch_size = 500
    offset = 0
    while (offset <= benefit_sponsorships.count)
      benefit_sponsorships.offset(offset).limit(batch_size).no_timeout.each do |benefit_sponsorship|
        begin
          benefit_application = benefit_sponsorship.benefit_applications.where(:created_at.gte => time).first
          benefit_sponsor_catalog = benefit_application.benefit_sponsor_catalog
          next if benefit_sponsor_catalog.product_packages.any? { |product_package| product_package.assigned_contribution_model.present? }

          benefit_sponsor_catalog.product_packages.where(product_kind: :health).each do |product_package|
            contribution_unit = product_package.contribution_model.contribution_units.where(name: :employee).first
            market_product_package = benefit_market_catalog.product_packages.where(product_kind: product_package.product_kind, package_kind: product_package.package_kind).first
            if contribution_unit.minimum_contribution_factor == 0
              assigned_contribution_model = market_product_package.contribution_models.detect { |contribution_model| contribution_model.key == :zero_percent_sponsor_fixed_percent_contribution_model }
              product_package.build_assigned_contribution_model(assigned_contribution_model.attributes)
              product_package.save
              puts "#{benefit_sponsorship.legal_name} - #{benefit_sponsor_catalog.created_at} - #{benefit_application.created_at} - #{benefit_application.start_on} - #{contribution_unit.minimum_contribution_factor} - #{contribution_unit.default_contribution_factor}" unless Rails.env.test?
            end
          end
          benefit_application.benefit_packages.each do |benefit_package|
            benefit_package.sponsored_benefits.each do |sponsored_benefit|
              sponsor_contribution = sponsored_benefit.sponsor_contribution
              sponsor_contribution.contribution_levels.each do |contribution_level|
                cu = sponsor_contribution.contribution_model.contribution_units.where(display_name: contribution_level.display_name).first
                raise "contribution_unit not found for benefit_sponsorship.legal_name - contribution_level id - #{contribution_level.id}" unless cu

                next if cu.id == contribution_level.contribution_unit_id
                contribution_level.update_attributes!(contribution_unit_id: cu.id)
              end
            end
          end
          benefit_application.save!
          benefit_sponsor_catalog.save!
        rescue Exception => e
          p "Unable to save assigned_contribution_model for #{benefit_sponsorship.legal_name} due to #{e.inspect}"
        end
      end
      offset = offset + batch_size
      puts "offset count - #{offset}"
    end
  end
end