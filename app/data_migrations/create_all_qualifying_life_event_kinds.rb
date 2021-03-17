# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# This classs provides a rarke task to create all QLE kinds with any rerfences in tooltips to states reflecting the settings files
class CreateAllQualifyingLifeEventKinds < MongoidMigrationTask
  def migrate
    puts "*" * 80
    puts "::: Beginnning Creation of QualifyingLifeEventKinds :::"
    existing_qles = []
    QualifyingLifeEventKind.pluck(:_id).each { |qlek_id| existing_qles << qlek_id }
    require File.join(Rails.root, "db", "seedfiles", 'qualifying_life_event_kinds_seed') #if EnrollRegistry.feature_enabled?(:aca_shop_market)
    require File.join(Rails.root, "db", "seedfiles", 'ivl_life_events_seed') if EnrollRegistry.feature_enabled?(:aca_individual_market)
    # the seed files specify is_visible
    QualifyingLifeEventKind.all.each do |qlek|
      puts("Publishing #{qlek.title} QLEK and setting active to true and start on date.") unless existing_qles.include?(qlek._id)
      qlek.update_attributes!(is_active: true, start_on: TimeKeeper.date_of_record) unless existing_qles.include?(qlek._id)
      qlek.publish! unless existing_qles.include?(qlek._id)
    end
    puts("There are a total of #{QualifyingLifeEventKind.all.count} QLE Kinds created for #{Settings.site.key}")
    %w[individual shop].each do |market_kind|
      puts("There are a total of #{QualifyingLifeEventKind.by_market_kind(market_kind).count} #{market_kind} QlE Kinds.")
    end
    puts "::: QualifyingLifeEventKinds Complete :::"
    puts "*" * 80
  end
end
