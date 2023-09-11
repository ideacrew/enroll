#RAILS_ENV=production bundle exec rake employers:export

require 'csv'

namespace :rrv_families do
  desc "Export RRV families to csv."
  task :export => [:environment] do

    assistance_year = 2023

    family_ids = ::FinancialAssistance::Application.where(:aasm_state => "determined",
                                                          :assistance_year => assistance_year,
                                                          :"applicants.is_ia_eligible" => true).exists(:predecessor_id => true).distinct(:family_id)

    p "found #{family_ids.count} families"

    CSV.open("export_rrv_families_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w") do |csv|

      csv << [
        'Primary HbxId',
        'Most recent determined 2023 application ID',
        'Most recent determined 2023 application determination date',
        'Latest active 2023 health plan HIOS-ID',
        'Latest active 2023 health plan state (autorenewing, coverage_selected etc)',
        'APTC applied on latest active health plan'
      ]

      counter = 0

      family_ids.each do |family_id|
        family = Family.where(:_id => family_id).first

        # determined_application = ::FinancialAssistance::Application.where(:family_id => family.id,
        #   :assistance_year => assistance_year,
        #   :aasm_state => 'determined',
        #   :"applicants.is_ia_eligible" => true).max_by(&:created_at)

        applications = ::FinancialAssistance::Application.where(:family_id => family.id,
                                                                :assistance_year => assistance_year,
                                                                :aasm_state => 'determined',
                                                                :"applicants.is_ia_eligible" => true)

        determined_application = applications.exists(:predecessor_id => true).max_by(&:created_at)
        next if determined_application.blank? || applications.any?{|application| application.created_at > determined_application.created_at}

        determined_at = determined_application.eligibility_determinations.max_by(&:created_at)&.determined_at
        health_coverage = family.active_household.hbx_enrollments.enrolled_and_renewing.individual_market.by_health.max_by(&:created_at)

        counter += 1

        p "processed #{counter} families" if counter % 100 == 0

        csv << [
          family.primary_applicant.hbx_id,
          determined_application.hbx_id,
          determined_at&.strftime('%m/%d/%Y'),
          health_coverage&.product&.hios_id,
          health_coverage&.aasm_state&.titleize,
          health_coverage&.applied_aptc_amount&.to_f
        ]
      end

      p counter
    end
  end
end