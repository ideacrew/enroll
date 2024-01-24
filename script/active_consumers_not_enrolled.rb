field_names  = %w(
               primary_hbx_id
               last_name
               communication_preference
               primary_email_address
               application_aasm_state
               application_aasm_state_date
               external_id
               user_account
               last_page_visited
               program_eligible_for
             )

file_name = "#{Rails.root}/family_with_no_enrollments.csv"
all_families = Family.where(:"_id".nin => HbxEnrollment.individual_market.by_year(2022).enrolled_and_renewing.distinct(:family_id))
batch_size = 500
offset = 0
families_count = all_families.count

puts "Total families with no enrollments #{families_count}"

def program_eligible_for(application)
  return if application.blank?

  active_applicants = application.active_applicants
  return if active_applicants.blank?

  eligible_programs = []
  eligible_programs << "Medicaid and CHIP(Medicaid)" if active_applicants.where(is_medicaid_chip_eligible: true).present?
  eligible_programs << "Financial assistance(APTC eligible)" if active_applicants.where(is_ia_eligible: true).present?
  eligible_programs << "Does not qualify" if active_applicants.where(is_totally_ineligible: true).present?
  eligible_programs << "Special Medicaid eligible" if application.applicants.pluck(:is_eligible_for_non_magi_reasons).any?(true)
  eligible_programs.join(",")
end

CSV.open(file_name, "w", force_quotes: true) do |csv|
  csv << field_names
  while (offset < families_count)
    all_families.offset(offset).limit(batch_size).no_timeout.each do |family|
      application = FinancialAssistance::Application.where(family_id: family._id, assistance_year: 2022).order_by(:created_at.desc).first
      primary_person = family.primary_person
      csv << [primary_person.hbx_id,
              primary_person.last_name,
              primary_person&.consumer_role&.contact_method,
              primary_person.work_email_or_best,
              application&.aasm_state,
              application&.workflow_state_transitions&.first&.transition_at,
              family.external_app_id,
              primary_person.user&.email,
              primary_person.user&.last_portal_visited,
              program_eligible_for(application)]
    rescue => e
      puts "error for family #{family.id} due to #{e}"
    end
    offset += batch_size
  end
end
