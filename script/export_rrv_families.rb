# frozen_string_literal: true

# This script generates a CSV report with information about families with renewal determined applications for the assistance_year with no SSN applicants.

# To run this on specific enrollments
# bundle exec rails runner script/export_rrv_families.rb assistance_year='2023'

assistance_year = ENV['assistance_year'].to_i

family_ids = ::FinancialAssistance::Application.by_year(assistance_year).determined.exists(:predecessor_id => true).where(:"applicants.is_ia_eligible" => true).distinct(:family_id)

p "found #{family_ids.count} families"  unless Rails.env.test?

CSV.open("export_rrv_families_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w") do |csv|
    csv << [
      'Primary HbxId',
      "Most recent determined #{assistance_year} application ID", 
      "Most recent determined #{assistance_year} application determination date",
      "Latest active #{assistance_year} health plan HIOS-ID",
      "Latest active #{assistance_year} health plan state (autorenewing, coverage_selected etc)", 
      'APTC applied on latest active health plan',
      'Applicants person hbx_id with out SSN'
    ]

    counter = 0

    family_ids.each do |family_id|
      family = Family.where(:_id => family_id).first

      applications = ::FinancialAssistance::Application.where(:family_id => family.id,
        :assistance_year => assistance_year,
        :aasm_state => 'determined',
        :"applicants.is_ia_eligible" => true)

      determined_application = applications.exists(:predecessor_id => true).max_by(&:created_at)
      next if determined_application.blank? || applications.any?{|application| application.created_at > determined_application.created_at}

      determined_at = determined_application.eligibility_determinations.max_by(&:created_at)&.determined_at
      health_coverage = family.active_household.hbx_enrollments.enrolled_and_renewing.individual_market.by_health.max_by(&:created_at)
      
      counter += 1

      result = determined_application.applicants.each_with_object({}) do |applicant, hash|
        hash[applicant.person_hbx_id] = applicant.ssn.present?
      end

      no_ssn_applicants_person_hbx_id = result.select{|k,v| v == false}.keys

      csv << [
        family.primary_applicant.hbx_id,
        determined_application.hbx_id,
        determined_at&.strftime('%m/%d/%Y'),
        health_coverage&.product&.hios_id,
        health_coverage&.aasm_state&.titleize,
        health_coverage&.applied_aptc_amount&.to_f,
        no_ssn_applicants_person_hbx_id
      ]
  end

  p "processed #{counter} families"  unless Rails.env.test?
end