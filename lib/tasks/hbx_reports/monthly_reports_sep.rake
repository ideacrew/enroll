require 'csv'
# RAILS_ENV=production bundle exec rake reports:monthly_reports_sep date="Month,Year"
namespace :reports do
 desc "Monthly sep enrollments report"
 task :monthly_reports_sep => :environment do

  def date
    begin
      ENV["date"].strip
    rescue
      puts 'Provide report month.'
    end
  end

  def start_date
    Date.parse(date)
  end

  def end_date
    Date.parse(date).next_month
  end

    file_name = "#{Rails.root}/monthly_sep_enrollments_report_#{date.gsub(" ", "").split(",").join("_")}.csv"
    puts "Created file and trying to import the data #{file_name}" 

    families = Family.monthly_reports_scope(start_date, end_date)

    CSV.open(file_name,"w") do |csv|
      csv <<  ["Subscriber ID",
        "Policy ID",
        "Primary First Name",
        "Primary Last Name",
        "SEP Type",
        "Date Of Enrollment",
        "Covered People",
        "Coverage Dental or health",
        "Plan Name",
        "HIOS ID",
        "No. of Enrollees"
      ]

      families.each do |family|
        begin
          hbx_enrollments = HbxEnrollment.enrollments_for_monthly_report_sep_scope(start_date, end_date, family.id)
          hbx_enrollments.each do |enrollment|
            primary_person = enrollment.family.primary_applicant.person
            covered_people = enrollment.hbx_enrollment_members.map(&:family_member).map(&:person).map(&:full_name)

            csv << [ 
              primary_person.hbx_id, 
              enrollment.hbx_id,
              primary_person.first_name,
              primary_person.last_name,
              enrollment.special_enrollment_period.title,
              enrollment.created_at.in_time_zone('Eastern Time (US & Canada)'),
              covered_people,
              enrollment.coverage_kind,
              enrollment.product.name,
              enrollment.product.hios_id,
              enrollment.hbx_enrollment_members.count
            ]
          end
        rescue Exception => e
          puts "exception - #{e}"
        end
      end
      puts "***** Done ******"
    end
  end
end
