require File.join(Rails.root, "lib/mongoid_migration_task")

class FixInvalidRelationshipBenefitInPlanYear < MongoidMigrationTask
  def migrate
    organizations = Organization.no_timeout.where("employer_profile" => {"$exists" => true})
    organizations.each do |org|
      org.employer_profile.plan_years.each do |plan_year|
        child_over_26_relationship_benefit= plan_year.benefit_groups.map(&:relationship_benefits).flatten.select{|r| r.relationship == "child_26_and_over"}.first
        if child_over_26_relationship_benefit.offered
          child_over_26_relationship_benefit.update_attribute(:offered, false)
          puts "#{org.employer_profile.legal_name} child_over_26_relationship_benefit updated"
        end
      end if org.employer_profile.plan_years.present?
    end
  end
end
