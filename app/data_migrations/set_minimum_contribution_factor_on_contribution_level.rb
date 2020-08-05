# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class SetMinimumContributionFactorOnContributionLevel < MongoidMigrationTask

  def migrate
    time = Date.new(2020,7,1).beginning_of_day

    benefit_sponsorships = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:benefit_applications => {:$elemMatch => {:"effective_period.min".gte => time}})

    batch_size = 50
    offset = 0
    while offset <= benefit_sponsorships.count
      benefit_sponsorships.offset(offset).limit(batch_size).no_timeout.each do |benefit_sponsorship|
        begin
          benefit_application = benefit_sponsorship.benefit_applications.where(:"effective_period.min".gte => time).first
          benefit_sponsor_catalog = benefit_application.benefit_sponsor_catalog
          benefit_application.benefit_packages.each do |benefit_package|
            sponsored_benefit = benefit_package.health_sponsored_benefit
            sponsor_contribution = sponsored_benefit.sponsor_contribution
            sponsor_contribution.contribution_levels.each do |contribution_level|
              if contribution_level.display_name =~ /Employee/i
                contribution_level.update_attributes!(min_contribution_factor: 0.5)
              else
                contribution_level.update_attributes!(min_contribution_factor: 0.33)
              end
              benefit_application.save!
              benefit_sponsor_catalog.save!
            end
          end
        rescue StandardError => e
          p "Unable to save assigned_contribution_model for #{benefit_sponsorship.legal_name} due to #{e.inspect}"
        end
      end
      offset += batch_size
      puts "offset count - #{offset}" unless Rails.env.test?
    end
  end
end

