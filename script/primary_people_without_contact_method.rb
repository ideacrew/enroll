# frozen_string_literal: true

# The below script gets the list of primary person hbx_ids who have missing
# contact_method and reports their information.
# bundle exec rails r script/primary_people_without_contact_method.rb

system_year = TimeKeeper.date_of_record.year
CSV.open("#{Rails.root}/primary_people_without_contact_method.csv", "w", force_quotes: true) do |csv|
  csv << [
    'Primary Person HBX ID',
    'Primary Person Name',
    'Primary Person Consumer Role Exists?',
    'Primary Person Contact Method',
    '2023 Latest Determined App HBX ID',
    '2023 Latest Determined App Aasm State',
    '2024 Latest Determined App HBX ID',
    '2024 Latest Determined App Aasm State'
  ]

  people_with_missing_contact_method = Person.all.where(:'consumer_role.contact_method' => nil)
  Family.where(:'family_members.person_id'.in => people_with_missing_contact_method.pluck(:id)).each do |family|
    primary = family.primary_person
    next family if primary.consumer_role&.contact_method.present?

    determined_apps = FinancialAssistance::Application.all.where(family_id: family.id, aasm_state: 'determined').order(created_at: :desc)
    current_application = determined_apps.where(assistance_year: system_year).first
    renewal_application = determined_apps.where(assistance_year: system_year.next).first

    csv << [
      primary.hbx_id,
      primary.full_name,
      primary.consumer_role.present?,
      primary.consumer_role&.contact_method,
      current_application&.hbx_id,
      current_application&.aasm_state,
      renewal_application&.hbx_id,
      renewal_application&.aasm_state
    ]
  end
end
