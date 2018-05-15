class GenerateCcaSite < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s == "mhc"
      say_with_time("Creating CCA Site") do
        # TODO: Bill, create the cca site here
      end
    end
  end

  def self.down
    raise "Migration is not reversable."
  end
end
