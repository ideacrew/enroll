require File.join(Rails.root, "lib/mongoid_migration_task")

class FixOrganization< MongoidMigrationTask
  def migrate
    organization = get_organization
    action = ENV['action'].to_s
    case action
      when "update_fein"
        update_fein(organization) if organization.present?
      else
        puts"The Action defined is not performed in the rake task"
    end
  end

  def get_organization
  organization_count = BenefitSponsors::Organizations::Organization.where(fein: ENV['organization_fein']).count
    if organization_count!= 1
      raise "No Organization found (or) found more than 1 Organization record" unless Rails.env.test?
    else
      organization = BenefitSponsors::Organizations::Organization.where(fein: ENV['organization_fein']).first
      return organization
    end
  end


  def update_fein(organization)
    correct_fein = ENV['correct_fein']
      org_with_correct_fein = BenefitSponsors::Organizations::Organization.where(fein: correct_fein).first
      if org_with_correct_fein.present?
         puts "Organization was found by the given fein: #{correct_fein}" unless Rails.env.test?
      else
        organization.fein=(correct_fein)
        organization.save!
        puts "Changed fein to #{correct_fein}" unless Rails.env.test?
      end
  end
end
