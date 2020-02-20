require 'csv'

#this report generate current IVL and SHOP enrollees from EnrollApp. 
# The task to run is RAILS_ENV=production bundle exec rake reports:enrollapp_report start_on="1/1/2020" end_on="12/31/2020"
# 
namespace :reports do
  desc "List of ivl and shop enrollees from EnrollApp"
  task :enrollapp_report => :environment do
    start_on = ENV['start_on']
    end_on = ENV['end_on']
    enrollments = HbxEnrollment.where(
      :"aasm_state".nin => ["shopping"],
      :effective_on => { "$gte" => Date.strptime(start_on, "%m/%d/%Y"), "$lt" => Date.strptime(end_on, "%m/%d/%Y")}
    )
    count = 0
    batch_size = 1000
    offset = 0
    total_count = enrollments.size
    timestamp = Time.now.strftime('%Y%m%d%H%M')
    CSV.open("enrollment_report_#{timestamp}.csv", 'w') do |csv|
      csv << ["Subscriber ID", "Member ID" , "Policy ID", "Enrollment Group ID", "Status",
              "First Name", "Last Name","SSN", "DOB", "Gender", "Relationship",
              "Plan Name", "HIOS ID", "Plan Metal Level", "Carrier Name",
              "Premium Amount", "Premium Total", "Policy APTC", "Policy Employer Contribution",
              "Coverage Start", "Coverage End",
              "Employer Name", "Employer DBA", "Employer FEIN", "Employer HBX ID",
              "Home Address", "Mailing Address","Email","Phone Number","Broker"]
      while offset<= total_count
        enrollments.offset(offset).limit(batch_size).no_timeout.each do |enr|
          count += 1
          begin
            if !enr.subscriber.nil?
              next if enr.subscriber.person.blank?
              family = enr.family
              primary_person = family.primary_person
              primary_person_hbx_id = primary_person.hbx_id
              product = Caches::MongoidCache.lookup(BenefitMarkets::Products::Product, enr.product_id) {
                enr.product
              }
              enr.hbx_enrollment_members.each do |en|
                per = en.person
                premium_amount = (enr.is_ivl_by_kind? ? enr.premium_for(en): (enr.decorated_hbx_enrollment.member_enrollments.find { |enrollment| enrollment.member_id == en.id }).product_price).to_f.round(2)
                next if per.blank?
                csv << [
                  primary_person_hbx_id, per.id, enr._id, enr.hbx_id, enr.aasm_state,
                  per.first_name,
                  per.last_name,
                  per.ssn,
                  per.dob.strftime("%Y%m%d"),
                  per.gender,
                  en.primary_relationship,
                  product.name, product.hios_id, product.metal_level, product.carrier_profile.abbrev,
                  premium_amount, enr.total_premium, en.applied_aptc_amount, enr.total_employer_contribution,
                  enr.effective_on.blank? ? nil : enr.effective_on.strftime("%Y%m%d"),
                  enr.terminated_on.blank? ? nil : enr.terminated_on.strftime("%Y%m%d"),
                  enr.employee_role_id.blank? ? nil : enr.employer_profile.legal_name,
                  enr.employee_role_id.blank? ? nil : enr.employer_profile.dba,
                  enr.employee_role_id.blank? ? nil : enr.employer_profile.fein,
                  enr.employee_role_id.blank? ? nil : enr.employer_profile.hbx_id,
                  per.home_address.try(:full_address) || enr.subscriber.person.home_address&.full_address,
                  per.mailing_address.try(:full_address) || enr.subscriber.person.mailing_address&.full_address,
                  per.emails.first.try(:email_address), per.phones.first&.phone_number, family&.active_broker_agency_account&.writing_agent&.person&.full_name
                ]
              end
            end
          rescue StandardError => e
            puts "Unable to process enrollment #{enr.hbx_id} due to error #{e}"
          end
        end
        offset = offset + batch_size
        puts "#{count}/#{total_count} done at #{Time.now}" if count % 10000 == 0
        puts "#{count}/#{total_count} done at #{Time.now}" if count == total_count
      end
      puts "End of the report" unless Rails.env.test?
    end
  end
end
