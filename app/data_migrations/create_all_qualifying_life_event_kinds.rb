# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# This classs provides a rarke task to create all QLE kinds with any rerfences in tooltips to states reflecting the settings files
class CreateAllQualifyingLifeEventKinds < MongoidMigrationTask
  def migrate
    puts "*" * 80
    puts "::: Cleaning QualifyingLifeEventKinds :::"
    QualifyingLifeEventKind.delete_all
    # Oly DC has SHOP
    require File.join(Rails.root, "db", "seedfiles", 'qualifying_life_event_kinds_seed') if Settings.site.key == :dc
    require File.join(Rails.root, "db", "seedfiles", 'ivl_life_events_seed')
    QualifyingLifeEventKind.update_all(is_active: true, is_visible: true)
    puts("There are a total of #{QualifyingLifeEventKind.all.count} QLE Kinds created for #{Settings.site.key}")
    %w[individual shop].each do |market_kind|
      puts("There are a total of #{QualifyingLifeEventKind.by_market_kind(market_kind).count} #{market_kind} QlE Kinds.")
    end
    puts "::: QualifyingLifeEventKinds Complete :::"
    puts "*" * 80
  end
end
