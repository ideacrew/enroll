class CreateMaPricingAndContributionModels < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "cca"
      require File.expand_path(File.join(Rails.root, "db/seedfiles/cca/pricing_and_contribution_models_seed"))
    else
      say("Skipping migration for non-MHC site")
    end
  end

  def self.down
    raise "Migration is not reversible."
  end
end
