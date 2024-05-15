# frozen_string_literal: true

# This script generates a CSV report with information about families with renewal determined applications for the assistance_year with no SSN applicants.

# To run this for specific year
# bundle exec rails runner script/export_pvc_families.rb assistance_year='2024'

assistance_year = ENV['assistance_year'].to_i
csr_list = [02, 04, 05, 06].freeze

family_ids = Family.with_applied_aptc_or_csr_active_enrollments(csr_list).distinct(:_id)

p "found #{family_ids.count} families"  unless Rails.env.test?

CSV.open("export_pvc_determined_families_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w") do |csv|
  csv << [
      "Primary Person Hbx ID",
      "Applicant Person Hbx ID",
      "Most recent Determined #{assistance_year} Application Hbx ID",
      "Is SSN Present",
      "Non ESI Evidence Title",
      "Workflow Transition From State",
      "Workflow Transition To State",
      "Verification History Action",
      "Verification History Update Reason",
      "Verification History Updated By",
      "Response Created At",
      "PVC Determination"
      ]

  counter = 0

  family_ids.each do |family_id|
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
      workflow_transition = non_esi_evidence.workflow_state_transitions.max_by(&:created_at)

      verification_history = non_esi_evidence.verification_histories.max_by(&:date_of_action)

      counter += 1

      csv << [
          primary_person.hbx_id,
          applicant.person_hbx_id,
          determined_application.hbx_id,
          applicant.encrypted_ssn.present?,
          non_esi_evidence.title,
          workflow_transition&.from_state,
          workflow_transition&.to_state,
          verification_history&.action,
          verification_history&.update_reason,
          verification_history&.updated_by,
          request_result&.created_at,
          pvc_determination
      ]
    end
  end

  p "processed #{counter} families"  unless Rails.env.test?
end
