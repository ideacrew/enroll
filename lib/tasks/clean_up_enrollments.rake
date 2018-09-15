namespace :migrate_enrollments do
  task :terminated_to_cancelled => :environment do
    action = ENV["action"]
    Dir.mkdir('hbx_report') unless File.exists?("hbx_report")
    file_name = "#{Rails.root}/hbx_report/terminated_enrollments_#{TimeKeeper.datetime_of_record.strftime("%m%d%Y%T")}.csv"
    families = Family.all.where(:"households.hbx_enrollments.aasm_state" => "coverage_terminated")
    count = 0
    fields = ["Primary Subscriber HBX ID", "Enrollment1 ID", "Enrollment1 HBX ID", "Enrollment1 state", "Enrollment1 Effective Date", "Enrollment1 terminated date", "Enrollment1 kind", "|", "Enrollment2 ID", "Enrollment2 HBX ID", "Enrollment2 state", "Enrollment2 Effective Date", "Enrollment2 terminated date", "Enrollment2 submitted date", "Enrollment2 kind"]
    CSV.open(file_name, 'w') do |csv|
      csv << fields
      families.each do |family|
        primary_member = family.primary_family_member.person
        enrollments = family.active_household.hbx_enrollments
        enrollments.where(:aasm_state => 'coverage_terminated').each do |terminated_enrollment|
          enrollments.where(:aasm_state.ne => 'shopping').each do |enrollment|
            next if enrollment == terminated_enrollment
            terminate_member = terminated_enrollment.hbx_enrollment_members.where(is_subscriber: true).first
            active_member = enrollment.hbx_enrollment_members.where(is_subscriber: true).first
            next unless terminate_member.present? && active_member.present?
            next unless terminate_member.applicant_id == active_member.applicant_id
            next unless enrollment.kind == terminated_enrollment.kind
            next unless terminated_enrollment.terminated_on == (terminated_enrollment.effective_on - 1.day)
            next unless enrollment.effective_on == terminated_enrollment.effective_on
            next unless enrollment.submitted_at.present? && terminated_enrollment.effective_on > enrollment.submitted_at
            count = count +1
            csv << [primary_member.hbx_id, terminated_enrollment.id, terminated_enrollment.hbx_id, terminated_enrollment.aasm_state, terminated_enrollment.effective_on, terminated_enrollment.terminated_on, terminated_enrollment.kind, '|', enrollment.id, enrollment.hbx_id, enrollment.aasm_state, enrollment.effective_on, enrollment.terminated_on, enrollment.submitted_at, enrollment.kind]
            if action.present? && action == "update_enrollments"
              print "." unless Rails.env.test?
              update_enrollments(enrollment, terminated_enrollment)
            end
          end
        end
      end
      puts "Total erroneously terminated enrollments: #{count}"
    end
  end
end

def self.update_enrollments (enrollment, terminated_enrollment)
  terminated_enrollment.update(aasm_state: 'coverage_canceled')
  terminated_enrollment.update(terminated_on: enrollment.effective_on)
end




