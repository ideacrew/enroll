# frozen_string_literal: true

require 'csv'

# bundle exec rails reports:ivl_osse_renewals[2024]
namespace :reports do
  desc "IVL osse renewal list"
  task :ivl_osse_renewals, [:renewal_year] => [:environment] do |_task, args|

    field_names  = %w[
      person_hbx_id
      is_enrolled
    ]

    year = args[:renewal_year]
    file_name = "#{Rails.root}/public/ivl_osse_renewals_#{year}.csv"

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      puts "Started reporting #{year} IVL OSSE renewals"
      csv << field_names

      eligible_people = Person.where({
        '$or' => [
          { 'consumer_role.eligibilities' => { :$elemMatch => { key: "aca_ivl_osse_eligibility_#{year}".to_sym, current_state: :eligible }}},
          { 'resident_role.eligibilities' => { :$elemMatch => { key: "aca_ivl_osse_eligibility_#{year}".to_sym, current_state: :eligible }}}
        ]
      })

      eligible_people.no_timeout.each do |person|
        csv << [
          person.hbx_id,
          person.has_active_enrollment
        ]
      rescue StandardError => e
        puts "Error while checking for #{person.hbx_id} with error - #{e}"
      end
    end
  end
end
