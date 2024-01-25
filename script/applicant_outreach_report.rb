# Script will output to the console the total time elapsed during exuction
start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
field_names = %w[
    primary_hbx_id
    first_name
    last_name
    dob
    communication_preference
    primary_email_address
    home_address
    mailing_address
    primary_phone
    secondary_phones
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
    FPL_year
    subscriber_hbx_id
    has_access_to_health_coverage
    has_access_to_health_coverage_kinds
  ]
curr_year = TimeKeeper.date_of_record.year
next_year = TimeKeeper.date_of_record.year + 1
field_names << "#{curr_year}_most_recent_health_plan_id"
field_names << "#{curr_year}_most_recent_health_status"
field_names << "#{next_year}_most_recent_health_plan_id"
field_names << "#{next_year}_most_recent_health_status"
field_names << "inbound_transfer_date"


file_name = "#{Rails.root}/applicant_outreach_report.csv"
enrollment_year = FinancialAssistance::Operations::EnrollmentDates::ApplicationYear.new.call.value!
# Target all families with an application in the current enrollment year
all_families = Family.where(:_id.in => FinancialAssistance::Application.by_year(enrollment_year).distinct(:family_id))
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

        primary_phone = applicant.phones.detect { |phone| phone.primary }
        secondary_phones = applicant.phones.each_with_object("") do |phone, collect|
            next if phone.primary
            collect.concat("#{phone}, ")
          end.chop.chop
        enrollments = family.active_household.hbx_enrollments
        mra_health_enrollment = enrollments.enrolled_and_renewal.detect {|enr| enr.coverage_kind == 'health'}
        mra_dental_enrollment = enrollments.enrolled_and_renewal.detect {|enr| enr.coverage_kind == 'dental'}
        enrollment_member = if mra_health_enrollment
                              mra_health_enrollment&.hbx_enrollment_members&.detect {|member| member.applicant_id == family_member.id}
                            else
                              mra_dental_enrollment&.hbx_enrollment_members&.detect {|member| member.applicant_id == family_member.id}
                            end
        fpl_year = application&.assistance_year - 1
        subscriber_id = if mra_health_enrollment
                          mra_health_enrollment&.subscriber&.hbx_id
                        else
                          mra_dental_enrollment&.subscriber&.hbx_id
                        end
        curr_mr_health_enrollment = enrollments.select {|enr| enr.coverage_kind == 'health' && enr.effective_on.year == curr_year}.sort_by(&:submitted_at).reverse.first
        next_mr_health_enrollment = enrollments.select {|enr| enr.coverage_kind == 'health' && enr.effective_on.year == next_year}.sort_by(&:submitted_at).reverse.first
        inbound_transfer_date = application.transferred_at if application.transferred_at.present? && application.transfer_id.present? && !application.account_transferred
        csv << [person.hbx_id,
                person.first_name,
                person.last_name,
                person&.dob,
                person&.consumer_role&.contact_method,
                person.work_email_or_best,
                applicant.home_address.to_s,
                applicant.addresses.where(kind: 'mailing').first,
                primary_phone,
                secondary_phones,
                application&.aasm_state,
                application&.workflow_state_transitions&.first&.transition_at,
                family.external_app_id,
                primary_person.user&.email, # only primary person has a User account
                primary_person.user&.last_portal_visited,
                program_eligible_for(applicant),
                mra_health_enrollment&.product&.hios_id,
                mra_dental_enrollment&.product&.hios_id,
                enrollment_member&.is_subscriber,
                application.transfer_id,
                fpl_year,
                subscriber_id,
                applicant.has_eligible_health_coverage,
                applicant.benefits.eligible.map(&:insurance_kind).join(", "),
                curr_mr_health_enrollment&.product&.hios_id,
                curr_mr_health_enrollment&.aasm_state,
                next_mr_health_enrollment&.product&.hios_id,
                next_mr_health_enrollment&.aasm_state,
                inbound_transfer_date
              ]
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