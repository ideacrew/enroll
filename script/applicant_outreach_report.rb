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
    health_plan_hios_id
    dental_plan_id
    subscriber_indicator
    transfer_id
  ]

file_name = "#{Rails.root}/applicant_outreach_report.csv"
enrollment_year = FinancialAssistance::Operations::EnrollmentDates::ApplicationYear.new.call.value!
all_families = Family.where(:_id.nin => HbxEnrollment.individual_market.by_year(enrollment_year).enrolled_and_renewing.distinct(:family_id))
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

CSV.open(file_name, "w", force_quotes: true) do |csv|
  csv << field_names
  while offset < families_count
    all_families.offset(offset).limit(batch_size).no_timeout.each do |family|
      application = FinancialAssistance::Application.where(family_id: family._id, assistance_year: enrollment_year).order_by(:created_at.desc).first
      primary_person = family.primary_person
      application.applicants.each do |applicant|
        family_member = family.family_members.detect {|fm| fm.hbx_id == applicant.person_hbx_id}
        person = family_member&.person
        next unless applicant.is_applying_coverage && person # assuming the report should skip non-applicants

        health_enrollment = family.active_household.active_hbx_enrollments.detect {|enr| enr.coverage_kind == 'health'}
        dental_enrollment = family.active_household.active_hbx_enrollments.detect {|enr| enr.coverage_kind == 'dental'}

        enrollment_member = health_enrollment&.hbx_enrollment_members&.detect {|member| member.applicant_id == family_member.id}
        enrollment_member ||= dental_enrollment&.hbx_enrollment_members&.detect {|member| member.applicant_id == family_member.id}
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
                health_enrollment&.plan&.hios_id,
                dental_enrollment&.plan&.hios_id,
                enrollment_member&.is_subscriber,
                application.transfer_id]
      end
    rescue StandardError => e
      puts "error for family #{family.id} due to #{e}"
    end
    offset += batch_size
  end
end
