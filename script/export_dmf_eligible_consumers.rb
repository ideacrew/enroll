# frozen_string_literal: true

# This script generates a CSV report which lists all consumers eligible to be included in a DMF call

# To run this script
# bundle exec rails runner script/export_dmf_eligible_consumers.rb

valid_eligibility_states = [
                            'health_product_enrollment_status',
                            'dental_product_enrollment_status'
                          ].freeze

family_ids = Family.with_applied_aptc_or_csr_active_enrollments(csr_list).distinct(:_id)

p "found #{family_ids.count} families"  unless Rails.env.test?

CSV.open("export_dmf_eligible_consumers_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}_#{Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%H:%M:%S')}.csv", "w") do |csv|
  csv << [
      "Family Hbx ID",
      "Person Hbx ID",
      "First Name",
      "Last Name",
      "Enrollment Type",
      "Enrollment Status"
      ]

  families_counter = 0
  applicants_counter = 0

  puts "Processing families" unless Rails.env.test?

  family_ids.each do |family_id|
    families_counter += 1
    puts "Processing family_id: #{family_id} and index at #{families_counter}" unless Rails.env.test?
    family = Family.where(:_id => family_id).first
    primary_person = family.primary_person

    applications = ::FinancialAssistance::Application.where(:family_id => family.id,
                                                            :assistance_year => assistance_year,
                                                            :aasm_state => 'determined',
                                                            :"applicants.is_ia_eligible" => true)

    determined_application = applications.max_by(&:submitted_at)
    next if determined_application.blank?

    determined_application.active_applicants.each do |applicant|
      non_esi_evidence = applicant.non_esi_evidence
      next if non_esi_evidence.blank?
      request_result = non_esi_evidence.request_results.max_by(&:date_of_action)
      pvc_determination = request_result&.result || 'no pvc result found'
      workflow_transition = non_esi_evidence.workflow_state_transitions.max_by(&:transition_at)
      verification_history = non_esi_evidence.verification_histories.max_by(&:date_of_action)

      applicants_counter += 1

      csv << [
          primary_person.hbx_id,
          applicant.person_hbx_id,
          determined_application.hbx_id,
          applicant.encrypted_ssn.present?,
          non_esi_evidence.title,
          workflow_transition&.transition_at,
          workflow_transition&.from_state,
          workflow_transition&.to_state,
          verification_history&.date_of_action,
          verification_history&.action,
          verification_history&.update_reason,
          verification_history&.updated_by,
          request_result&.date_of_action,
          pvc_determination
      ]
    end
  end
  p "processed #{applicants_counter} applicants"  unless Rails.env.test?
  p "processed #{families_counter} families"  unless Rails.env.test?
end
