desc "Run a report for enrollment eligibility"
task :enrollment_renewal_eligibility_report => :environment do
  file_name = "#{Rails.root}/enrollment_eligibility_report_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv"
  field_names = %w[EnrollmentHbxId EnrollmentAASMState PrimaryHbxID MemberHbxID MemberFirstName MemberLastName MemberDOB member-is_applying_coverage member-citizen_status member-is_incarcerated member-state member_present_in_manage_family? applicant-is_applying_coverage applicant-citizen_status applicant-is_incarcerated applicant-state error_message]
  CSV.open(file_name, 'w', force_quotes: true) do |csv|
    csv << field_names
    active_enrollments = HbxEnrollment.where(:kind.in => %w[individual coverall], :aasm_state.nin => %w[shopping coverage_canceled coverage_terminated coverage_expired])
    total_count = active_enrollments.count
    block_size = 1_000.0
    number_of_iterations = (total_count / block_size).ceil
    counter = 0
    while counter < number_of_iterations
      offset_count = block_size * counter
      active_enrollments.no_timeout.limit(block_size).offset(offset_count).each do |enrollment|
        begin
          family = enrollment.family
          next unless family

          app = FinancialAssistance::Application.where(family_id: family.id, :aasm_state.in => [:determined, :submitted])&.last
          active_family_member_ids = family.active_family_members.map(&:id).flatten
          primary_person = family.primary_person
          enrollment.hbx_enrollment_members.each do |enrollment_member|
            applicant = app&.applicants&.where(:family_member_id => enrollment_member.applicant_id)&.first
            member_person = enrollment_member.person

            csv << [enrollment.hbx_id,
                    enrollment.aasm_state,
                    primary_person.hbx_id,
                    member_person.hbx_id,
                    member_person.first_name,
                    member_person.last_name,
                    member_person.dob,
                    member_person.is_applying_coverage,
                    member_person.citizen_status,
                    member_person.is_incarcerated,
                    member_person.rating_address&.state,
                    active_family_member_ids.include?(enrollment_member.applicant_id),
                    applicant&.is_applying_coverage,
                    applicant&.citizen_status,
                    applicant&.is_incarcerated,
                    applicant&.home_address&.state]
          end
        rescue => e
          puts "Error: #{e.message}"
          csv << [enrollment.hbx_id, enrollment.aasm_state, field_names[2..-2].map { |_field| nil }, e.message].flatten
          next
        end
      end
      counter += 1
    end
  end
end
