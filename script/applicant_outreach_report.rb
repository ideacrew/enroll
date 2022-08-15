# Script will output to the console the total time elapsed during exuction
start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
field_names = %w[
    primary_hbx_id
    first_name
    last_name
    communication_preference
    primary_email_address
    home_address
    mailing_address
    application_aasm_state
    application_aasm_state_date
    external_id
    user_account
    last_page_visited
    program_eligible_for
    most_recent_active_health_plan_id
    most_recent_active_dental_plan_id
    subscriber_indicator
    transfer_id
  ]
file_name = "#{Rails.root}/applicant_outreach_report.csv"
enrollment_year = FinancialAssistance::Operations::EnrollmentDates::ApplicationYear.new.call.value!
# Target all families with an application in the current enrollment year
all_families = Family.where(:_id.in => FinancialAssistance::Application.by_year(enrollment_year).distinct(:family_id))
batch_size = 500
offset = 0
families_count = all_families.count

def program_eligible_for(application)
  return if application.blank?

  active_applicants = application.active_applicants
  return if active_applicants.blank?

  eligible_programs = []
  eligible_programs << "MaineCare and Cub Care(Medicaid)" if active_applicants.where(is_medicaid_chip_eligible: true).present?
  eligible_programs << "Financial assistance(APTC eligible)" if active_applicants.where(is_ia_eligible: true).present?
  eligible_programs << "Does not qualify" if active_applicants.where(is_totally_ineligible: true).present?
  eligible_programs << "Special Maine care eligible" if application.applicants.pluck(:is_eligible_for_non_magi_reasons).any?(true)
  eligible_programs.join(",")
end

puts "Generating applicant outreach report...."
CSV.open(file_name, "w", force_quotes: true) do |csv|
  csv << field_names
  while offset < families_count
    all_families.offset(offset).limit(batch_size).no_timeout.each do |family|
      application = FinancialAssistance::Application.where(family_id: family._id, assistance_year: enrollment_year).order_by(:created_at.desc).first
      primary_person = family.primary_person
      application.applicants.each do |applicant|
        family_member = family.family_members.detect {|fm| fm.hbx_id == applicant.person_hbx_id}
        person = family_member&.person
        next unless applicant.is_applying_coverage && person

        health_enrollment = family.active_household.hbx_enrollments.enrolled_and_renewal.detect {|enr| enr.coverage_kind == 'health'}
        dental_enrollment = family.active_household.hbx_enrollments.enrolled_and_renewal.detect {|enr| enr.coverage_kind == 'dental'}
        enrollment_member = if health_enrollment
                              health_enrollment&.hbx_enrollment_members&.detect {|member| member.applicant_id == family_member.id}
                            else
                              enrollment_member = dental_enrollment&.hbx_enrollment_members&.detect {|member| member.applicant_id == family_member.id}
                            end
        csv << [person.hbx_id,
                person.first_name,
                person.last_name,
                person&.consumer_role&.contact_method,
                person.work_email_or_best,
                applicant.home_address.to_s,
                applicant.addresses.where(kind: 'mailing').first,
                application&.aasm_state,
                application&.workflow_state_transitions&.first&.transition_at,
                family.external_app_id,
                primary_person.user&.email, # only primary person has a User account
                primary_person.user&.last_portal_visited,
                program_eligible_for(application),
                health_enrollment&.product&.hios_id,
                dental_enrollment&.product&.hios_id,
                enrollment_member&.is_subscriber,
                application.transfer_id]
      end
    rescue StandardError => e
      puts "error for family #{family.id} due to #{e}"
    end
    offset += batch_size
  end
end
puts "Applicant outreach report complete. Output file is located at: #{file_name}"
end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
seconds_elapsed = end_time - start_time
hr_min_sec = format("%02dhr %02dmin %02dsec", seconds_elapsed / 3600, seconds_elapsed / 60 % 60, seconds_elapsed % 60)
puts "Total time for report to complete: #{hr_min_sec}"