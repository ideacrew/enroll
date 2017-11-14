# Daily Report: Rake task to find Multi Active IVL enrollments
# Run this task every Day: RAILS_ENV=production bundle exec rake reports:ivl:multiple_active_ivl_enrollments

require 'csv'
 
namespace :reports do
  namespace :ivl do

    desc "Multi Active IVL enrollments"
    task :multiple_active_ivl_enrollments, [:file] => :environment do

      field_names = %w(
        HBX_ID
        PRIMARY_FIRST_NAME
        PRIMARY_LAST_NAME
        DEPENDENT_HBX_ID
        DEPENDENT_FIRST_NAME
        DEPENDENT_LAST_NAME
        ENROLLMENT_HBX_ID
        MARKET_KIND
        STATE
        PLAN_HIOS
        COVERAGE_START_DATE
        COVERAGE_END_DATE
      )

      processed_count = 0
      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_path = "#{Rails.root}/hbx_report/multiple_active_ivl_enrollments.csv"
      CSV.open(file_path, "w", force_quotes: true) do |csv|
        csv << field_names

        families = Family.where(:"households.hbx_enrollments.kind" => "individual", :"households.hbx_enrollments.aasm_state".in => HbxEnrollment::ENROLLED_STATUSES)
        families.each do |family|
          begin
            health_enrollments, dental_enrollments = family.households.flat_map(&:hbx_enrollments).partition { |enr| enr.coverage_kind == "health"} 
            ivl_health_enrollments, shop_health_enrollments = health_enrollments.partition {|enr| enr.kind == "individual"}
            ivl_dental_enrollments, shop_dental_enrollments = dental_enrollments.partition {|enr| enr.kind == "individual"}
            active_ivl_health_enrollments = ivl_health_enrollments.select { |enr| (HbxEnrollment::ENROLLED_STATUSES).include? enr.aasm_state }
            active_ivl_dental_enrollments = ivl_dental_enrollments.select { |enr| (HbxEnrollment::ENROLLED_STATUSES).include? enr.aasm_state }
            
            if (active_ivl_health_enrollments.size > 1)
              active_ivl_health_enrollments.each do |enr|
                enr.hbx_enrollment_members.each do |dep|
                  primary = dep.person.families.first.primary_applicant.person
                  csv << [enr.subscriber.present? ? enr.subscriber.person.hbx_id : primary.hbx_id,
                          enr.subscriber.present? ? enr.subscriber.person.first_name : primary.first_name, 
                          enr.subscriber.present? ? enr.subscriber.person.last_name : primary.last_name,
                          dep.is_subscriber ? '---' : dep.person.hbx_id,
                          dep.is_subscriber ? '---' : dep.person.first_name,
                          dep.is_subscriber ? '---' : dep.person.last_name,
                          enr.hbx_id,
                          enr.coverage_kind,
                          enr.aasm_state,
                          enr.plan.hios_id,
                          enr.effective_on,
                          enr.terminated_on
                         ]
                  processed_count +=1
                end
              end
            end
            
            if (active_ivl_dental_enrollments.size > 1)
              active_ivl_dental_enrollments.each do |enr|
                enr.hbx_enrollment_members.each do |dep|
                  primary = dep.person.families.first.primary_applicant.person
                  csv << [enr.subscriber.present? ? enr.subscriber.person.hbx_id : primary.hbx_id,
                          enr.subscriber.present? ? enr.subscriber.person.first_name : primary.first_name, 
                          enr.subscriber.present? ? enr.subscriber.person.last_name : primary.last_name,
                          dep.is_subscriber ? '---' : dep.person.hbx_id,
                          dep.is_subscriber ? '---' : dep.person.first_name,
                          dep.is_subscriber ? '---' : dep.person.last_name,
                          enr.hbx_id,
                          enr.coverage_kind,
                          enr.aasm_state,
                          enr.plan.hios_id,
                          enr.effective_on,
                          enr.terminated_on
                         ]
                  processed_count +=1
                end
              end
            end
          rescue Exception => e
            puts e.message
          end
        end
        puts "File path: %s. Total count of Multi Active IVL enrollments: %d." %[file_path, processed_count]
      end
    end
  end
end
