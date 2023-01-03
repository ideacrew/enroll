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
    program_eligible_for
    application_aasm_state
    application_aasm_state_date
    transfer_id
    inbound_transfer_date
    FPL
    has_access_to_health_coverage
    has_access_to_health_coverage_kinds
  ]
curr_year = TimeKeeper.date_of_record.year
next_year = TimeKeeper.date_of_record.year + 1
field_names << "#{curr_year}_most_recent_health_plan_id"
field_names << "#{curr_year}_most_recent_health_status"
field_names << "#{next_year}_most_recent_health_plan_id"
field_names << "#{next_year}_most_recent_health_status"
field_names << "#{curr_year}_most_recent_dental_plan_id"
field_names << "#{curr_year}_most_recent_dental_status"
field_names << "#{next_year}_most_recent_dental_plan_id"
field_names << "#{next_year}_most_recent_dental_status"

file_name = "#{Rails.root}/member_outreach_report.csv"
all_families = Family.all
batch_size = 500
offset = 0
families_count = all_families.count

def program_eligible_for(applicant)
  return if applicant.blank?
  eligible_programs = []
  eligible_programs << "MaineCare and Cub Care(Medicaid)" if applicant.is_medicaid_chip_eligible
  eligible_programs << "Financial assistance(APTC eligible)" if applicant.is_ia_eligible
  eligible_programs << "Does not qualify" if applicant.is_totally_ineligible
  eligible_programs << "QHP without financial assistance" if applicant.is_without_assistance
  eligible_programs << "Special Maine care eligible" if applicant.is_eligible_for_non_magi_reasons
  eligible_programs.join(",")
end

def fpl_percentage(enr, enr_member, effective_year)
  return unless enr && enr_member
  tax_households = if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
                     enr.family.tax_household_groups.active.by_year(effective_year).first&.tax_households
                   else
                     enr.household.latest_tax_households_with_year(effective_year).active_tax_household
                   end
  return "N/A" if tax_households.blank?

  tax_household_member = tax_households.map(&:tax_household_members).flatten.detect{|mem| mem.applicant_id == enr_member.applicant_id}
  tax_household_member&.magi_as_percentage_of_fpl
end

puts "Generating member outreach report...."
CSV.open(file_name, "w", force_quotes: true) do |csv|
  csv << field_names
  while offset < families_count
    all_families.offset(offset).limit(batch_size).no_timeout.each do |family|
      application = FinancialAssistance::Application.where(family_id: family._id).order_by(:created_at.desc).first
      primary_person = family.primary_person
      family.family_members.each do |family_member|
        person = family_member&.person
        applicant = application&.applicants&.detect {|a| a.person_hbx_id == person.hbx_id}
        # what is considered primary phone?  assumption: use home phone
        home_phone = person.phones.detect { |phone| phone.kind == 'home' }
        work_phone = person.phones.detect { |phone| phone.kind == 'work' }
        mobile_phone = person.phones.detect { |phone| phone.kind == 'mobile' }
        enrollments = family.active_household.hbx_enrollments
        mra_health_enrollment = enrollments.enrolled_and_renewal.effective_desc.detect {|enr| enr.coverage_kind == 'health'}
        mra_dental_enrollment = enrollments.enrolled_and_renewal.effective_desc.detect {|enr| enr.coverage_kind == 'dental'}
        enrollment_member = if mra_health_enrollment
                              mra_health_enrollment&.hbx_enrollment_members&.detect {|member| member.applicant_id == family_member.id}
                            else
                              mra_dental_enrollment&.hbx_enrollment_members&.detect {|member| member.applicant_id == family_member.id}
                            end
        curr_mr_health_enrollment = enrollments.enrolled_and_renewal.select {|enr| enr.coverage_kind == 'health' && enr.effective_on&.year == curr_year}.sort_by(&:submitted_at).reverse.first
        next_mr_health_enrollment = enrollments.enrolled_and_renewal.select {|enr| enr.coverage_kind == 'health' && enr.effective_on&.year == next_year}.sort_by(&:submitted_at).reverse.first
        curr_mr_dental_enrollment = enrollments.enrolled_and_renewal.select {|enr| enr.coverage_kind == 'dental' && enr.effective_on&.year == curr_year}.sort_by(&:submitted_at).reverse.first
        next_mr_dental_enrollment = enrollments.enrolled_and_renewal.select {|enr| enr.coverage_kind == 'dental' && enr.effective_on&.year == next_year}.sort_by(&:submitted_at).reverse.first
        inbound_transfer_date = application.transferred_at if application&.transferred_at.present? && application&.transfer_id.present? && !application&.account_transferred

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
            program_eligible_for(applicant),
            application&.aasm_state,
            application&.workflow_state_transitions&.first&.transition_at,
            application&.transfer_id,
            inbound_transfer_date,
            # fpl depends on enrollment; assumption: use most recent active health plan enrollment
            fpl_percentage(mra_health_enrollment, enrollment_member, mra_health_enrollment&.effective_on&.year),
            applicant&.has_eligible_health_coverage.present?,
            applicant&.benefits&.eligible&.map(&:insurance_kind)&.join(", "),
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