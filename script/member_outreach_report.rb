# frozen_string_literal: true

# Script will output to the console the total time elapsed during exuction
start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
field_names = %w[
    subscriber_hbx_id
    member_hbx_id
    subscriber_indicator
    first_name
    last_name
    dob
    communication_preference
    primary_email_address
    home_address
    mailing_address
    home_phone
    work_phone
    mobile_phone
    external_id
    user_account
    last_page_visited
    latest_determined_application_id
    determined_date
    determined_program_eligible_for
    determined_medicaid_fpl
    determined_has_access_to_coverage
    determined_has_access_to_coverage_kinds
    latest_application_aasm_state
    latest_application_aasm_state_date
    latest_transfer_id
    latest_inbound_transfer_date
  ]

benefit_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
current_coverage_period_year = benefit_sponsorship.current_benefit_period.start_on.year
field_names << "#{current_coverage_period_year - 1}_most_recent_health_plan_id"
field_names << "#{current_coverage_period_year - 1}_most_recent_health_status"
field_names << "#{current_coverage_period_year}_most_recent_health_plan_id"
field_names << "#{current_coverage_period_year}_most_recent_health_status"
field_names << "#{current_coverage_period_year - 1}_most_recent_dental_plan_id"
field_names << "#{current_coverage_period_year - 1}_most_recent_dental_status"
field_names << "#{current_coverage_period_year}_most_recent_dental_plan_id"
field_names << "#{current_coverage_period_year}_most_recent_dental_status"

file_name = "#{Rails.root}/member_outreach_report.csv"
all_families = Family.all
batch_size = 500
offset = 0
families_count = all_families.count

def program_eligible_for(applicant)
  return if applicant.blank?
  eligible_programs = []
  eligible_programs << "Medicaid and CHIP(Medicaid)" if applicant.is_medicaid_chip_eligible
  eligible_programs << "Financial assistance(APTC eligible)" if applicant.is_ia_eligible
  eligible_programs << "Does not qualify" if applicant.is_totally_ineligible
  eligible_programs << "QHP without financial assistance" if applicant.is_without_assistance
  eligible_programs << "Special Medicaid eligible" if applicant.is_eligible_for_non_magi_reasons
  eligible_programs.join(",")
end

puts "Generating member outreach report...."
CSV.open(file_name, "w", force_quotes: true) do |csv|
  csv << field_names
  while offset < families_count
    all_families.offset(offset).limit(batch_size).no_timeout.each do |family|
      latest_determined_application = FinancialAssistance::Application.where(family_id: family._id).determined.order_by(:created_at.desc).first
      latest_application = FinancialAssistance::Application.where(family_id: family._id).order_by(:created_at.desc).first
      primary_person = family.primary_person
      family.family_members.each do |family_member|
        person = family_member&.person
        applicant = latest_determined_application&.applicants&.detect {|a| a.person_hbx_id == person.hbx_id}
        # what is considered primary phone?  assumption: use home phone
        home_phone = person.phones.detect { |phone| phone.kind == 'home' }
        work_phone = person.phones.detect { |phone| phone.kind == 'work' }
        mobile_phone = person.phones.detect { |phone| phone.kind == 'mobile' }
        enrolled_and_renewal = family.active_household.hbx_enrollments.enrolled_and_renewal
        canceled_and_terminated = family.active_household.hbx_enrollments.canceled_and_terminated
        enrollments = enrolled_and_renewal + canceled_and_terminated
        mra_health_enrollment = enrolled_and_renewal.effective_desc.detect {|enr| enr.coverage_kind == 'health'}
        mra_dental_enrollment = enrolled_and_renewal.effective_desc.detect {|enr| enr.coverage_kind == 'dental'}
        enrollment_member = if mra_health_enrollment
                              mra_health_enrollment&.hbx_enrollment_members&.detect {|member| member.applicant_id == family_member.id}
                            else
                              mra_dental_enrollment&.hbx_enrollment_members&.detect {|member| member.applicant_id == family_member.id}
                            end

        curr_mr_health_enrollment = enrollments.select {|enr| enr.coverage_kind == 'health' && enr.effective_on&.year == current_coverage_period_year - 1}.sort_by(&:submitted_at).reverse.first
        next_mr_health_enrollment = enrollments.select {|enr| enr.coverage_kind == 'health' && enr.effective_on&.year == current_coverage_period_year}.sort_by(&:submitted_at).reverse.first
        curr_mr_dental_enrollment = enrollments.select {|enr| enr.coverage_kind == 'dental' && enr.effective_on&.year == current_coverage_period_year - 1}.sort_by(&:submitted_at).reverse.first
        next_mr_dental_enrollment = enrollments.select {|enr| enr.coverage_kind == 'dental' && enr.effective_on&.year == current_coverage_period_year}.sort_by(&:submitted_at).reverse.first
        inbound_transfer_date = latest_application.transferred_at if latest_application&.transferred_at.present? && latest_application&.transfer_id.present? && !latest_application&.account_transferred
        aasm_state_date = latest_application&.aasm_state == 'draft' ? latest_application.created_at : latest_application&.workflow_state_transitions&.first&.transition_at

        csv << [
            family.primary_applicant.hbx_id,
            person.hbx_id,
            enrollment_member&.is_subscriber.present?,
            person.first_name,
            person.last_name,
            person&.dob,
            person&.consumer_role&.contact_method,
            person.work_email_or_best,
            person.home_address.to_s,
            person.mailing_address,
            home_phone,
            work_phone,
            mobile_phone,
            family.external_app_id,
            primary_person.user&.email, # only primary person has a User account
            primary_person.user&.last_portal_visited,
            latest_determined_application&.hbx_id,
            latest_determined_application&.submitted_at,
            program_eligible_for(applicant),
            # Expected outcome is that FPL value populates for all FAA applicants based on most recent determined application
            applicant&.magi_as_percentage_of_fpl,
            applicant&.has_eligible_health_coverage.present?,
            applicant&.benefits&.eligible&.map(&:insurance_kind)&.join(", "),
            latest_application&.aasm_state,
            aasm_state_date,
            latest_application&.transfer_id,
            inbound_transfer_date,
            curr_mr_health_enrollment&.product&.hios_id,
            curr_mr_health_enrollment&.aasm_state,
            next_mr_health_enrollment&.product&.hios_id,
            next_mr_health_enrollment&.aasm_state,
            curr_mr_dental_enrollment&.product&.hios_id,
            curr_mr_dental_enrollment&.aasm_state,
            next_mr_dental_enrollment&.product&.hios_id,
            next_mr_dental_enrollment&.aasm_state
          ]
      end
    rescue StandardError => e
      puts "error for family #{family.id} due to #{e}"
    end
    offset += batch_size
  end
end
puts "Member outreach report complete. Output file is located at: #{file_name}"
end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
seconds_elapsed = end_time - start_time
hr_min_sec = format("%02dhr %02dmin %02dsec", seconds_elapsed / 3600, seconds_elapsed / 60 % 60, seconds_elapsed % 60)
puts "Total time for report to complete: #{hr_min_sec}"