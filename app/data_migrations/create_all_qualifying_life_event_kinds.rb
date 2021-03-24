# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# This classs provides a rarke task to create all QLE kinds with any rerfences in tooltips to states reflecting the settings files
class CreateAllQualifyingLifeEventKinds < MongoidMigrationTask
  def migrate
    puts "*" * 80
    puts "::: Beginnning Creation of QualifyingLifeEventKinds :::"
    existing_qles = []
    QualifyingLifeEventKind.pluck(:_id).each { |qlek_id| existing_qles << qlek_id }
    require File.join(Rails.root, "db", "seedfiles", 'qualifying_life_event_kinds_seed') if EnrollRegistry.feature_enabled?(:aca_shop_market)
    require File.join(Rails.root, "db", "seedfiles", 'ivl_life_events_seed') if EnrollRegistry.feature_enabled?(:aca_individual_market)
    # the seed files specify is_visible
    QualifyingLifeEventKind.all.each do |qlek|
      puts("Publishing #{qlek.title} QLEK and setting active to true and start on date.") unless existing_qles.include?(qlek._id)
      qlek.update_attributes!(is_active: true, start_on: TimeKeeper.date_of_record) unless existing_qles.include?(qlek._id)
      qlek.publish! unless existing_qles.include?(qlek._id)
    end
    puts("There are a total of #{QualifyingLifeEventKind.all.count} QLE Kinds created for #{EnrollRegistry[:enroll_app].setting(:site_key).item}")
    %w[individual shop].each do |market_kind|
      puts("There are a total of #{QualifyingLifeEventKind.by_market_kind(market_kind).count} #{market_kind} QlE Kinds.")
    end
    puts "::: QualifyingLifeEventKinds Complete :::"
    puts "*" * 80
    # generate_qlek_csv
  end

  # Only used for creaeting a report of all Qualifying Life Event Kinds for a given client
  # Do not uncomment or run if not on environment
  def generate_qlek_csv
    return unless Rails.env.development?
    puts("Beginning Qualifying Life Event Kind report")
    field_names = [
      "event_kind_label", "action_kind", "title", "effective_on_kinds", "reason", "edi_code",
      "market_kind", "tool_tip", "pre_event_sep_in_days", "is_self_attested", "date_options_available", "post_event_sep_in_days",
      "ordinal_position", "aasm_state", "is_active", "event_on", "qle_event_date_kind", "coverage_effective_on",
      "start_on", "end_on", "is_visible", "termination_on_kinds", "coverage_start_on", "coverage_end_on",
      "updated_by", "published_by", "created_by"
    ]
    file_name = "#{Rails.root}/qualifying_life_event_kinds_report.csv"
    FileUtils.touch(file_name) unless File.exist?(file_name)
    qleks = QualifyingLifeEventKind.all
    CSV.open(file_name, 'w+', headers: true) do |csv|
      csv << field_names
      qleks.each do |qlek|
        qlek_attrs = qlek.attributes
        csv << field_names.map { |field_name| qlek_attrs[field_name] }
      end
    end
    puts("Finished Qualifying Life Event Kind report")
  end
end
