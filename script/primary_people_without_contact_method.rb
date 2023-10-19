# frozen_string_literal: true

# The below script gets the list of primary person hbx_ids who have missing
# contact_method and reports their information.
# bundle exec rails r script/primary_people_without_contact_method.rb

system_year = TimeKeeper.date_of_record.year
CSV.open("#{Rails.root}/primary_people_without_contact_method.csv", "w", force_quotes: true) do |csv|
  csv << [
    'Family External App ID',
    'Primary Person HBX ID',
    'Primary Person Name',
    'Primary Person Consumer Role Exists?',
    'Primary Person Contact Method',
    'Current Year Latest Determined App HBX ID',
    'Current Year Latest Determined App Aasm State',
    'Prospective Year Latest Determined App HBX ID',
    'Prospective Year Latest Determined App Aasm State',
    'Apps with transfer id'
  ]

  people_with_missing_contact_method = Person.all.where(:'consumer_role.contact_method' => nil)
  Family.where(:'family_members.person_id'.in => people_with_missing_contact_method.pluck(:id)).each do |family|
    primary = family.primary_person
    next family if primary.consumer_role&.contact_method.present?

    determined_apps = FinancialAssistance::Application.all.where(family_id: family.id, aasm_state: 'determined').order(created_at: :desc)
    current_application = determined_apps.where(assistance_year: system_year).first
    renewal_application = determined_apps.where(assistance_year: system_year.next).first

    apps_info = FinancialAssistance::Application.all.where(
      family_id: family.id, :transfer_id.exists => true
    ).pluck(
      :hbx_id, :transfer_id, :aasm_state
    ).inject({}) do |combos, app_info|
      combos[app_info[0]] = { transfer_id: app_info[1], aasm_state: app_info[2] }
      combos
    end

    csv << [
      family.external_app_id,
      primary.hbx_id,
      primary.full_name,
      primary.consumer_role.present?,
      primary.consumer_role&.contact_method,
      current_application&.hbx_id,
      current_application&.aasm_state,
      renewal_application&.hbx_id,
      renewal_application&.aasm_state,
      apps_info
    ]
  end
end
