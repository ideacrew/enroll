class CreateMaPricingAndContributionModels < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "mhc"
      say_with_time("Loading MA pricing and contribution models") do
        require File.join(Rails.root, "db/seedfiles/ma_employer_pricing_and_contribution_models")
      end
    else
      say("Skipping migration for non-MHC site")
    end
  end

  def self.down
    raise "Migration is not reversible."
  end
end
