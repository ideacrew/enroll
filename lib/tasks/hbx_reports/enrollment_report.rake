# frozen_string_literal: true

require 'rake'
# The task to run is RAILS_ENV=production bundle exec rake reports:enrollment_report_generate start_on="1/1/2022" end_on="12/31/2022"
namespace :reports do
  desc 'List of enrollments for the given dates'
  task enrollment_report_generate: :environment do
    start_on = ENV['start_on']
    end_on = ENV['end_on']

    def fpl_percentage(enr, enr_member, effective_year)
      tax_households = enr.household.latest_tax_households_with_year(effective_year).active_tax_household
      return "N/A" if tax_households.blank?

      tax_household_member = tax_households.map(&:tax_household_members).flatten.detect{|mem| mem.applicant_id == enr_member.applicant_id}
      tax_household_member&.magi_as_percentage_of_fpl
    end

    def total_responsible_amount(enr)
      (enr.total_premium - enr.applied_aptc_amount.to_f).to_f.round(2)
    end

    def member_status(enr)
      enrollments = enr.family.hbx_enrollments.where(:effective_on.lt => ENV['start_on'],
                                                     :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES,
                                                     coverage_kind: enr.coverage_kind,
                                                     :external_id.exists => true,
                                                     :consumer_role_id.ne => nil)

      if enr.external_id.blank? && enrollments.present?
        "Active Re-enrollee"
      elsif enr.aasm_state == "auto_renewing" || (enr.external_id.present? && enrollments.any? {|enrollment| enrollment.subscriber.hbx_id == enr.subscriber.hbx_id})
        "Re-enrollee"
      else
        "New Consumer"
      end
    end

    def broker_assisted(enr, person)
      broker_role = person&.user.present? ? (person.broker_role || person.active_broker_staff_roles) : nil
      return "No" if broker_role.present?

      enr.writing_agent_id.present? ? "Yes" : "No"
    end

    def ethnicity_status(ethnicity)
      return "unknown" if ethnicity.blank?

      if ethnicity.include?("Mexican") || ethnicity.include?("Mexican American")
        "hispanic"
      else
        "non-hispanic"
      end
    end

    enrollments = HbxEnrollment.where(
      :aasm_state.nin => ["coverage_canceled", 'shopping'],
      :effective_on => { "$gte" => Date.strptime(start_on, "%m/%d/%Y"), "$lt" => Date.strptime(end_on, "%m/%d/%Y")}
    )
    count = 0
    batch_size = 1000
    offset = 0
    total_count = enrollments.size
    timestamp = Time.now.strftime('%Y%m%d%H%M')
    CSV.open("enrollment_report_#{timestamp}.csv", 'w') do |csv|
      csv << ["Primary Member ID", "Member ID", "Policy ID", "Policy Subscriber ID " "Status", "Member Status",
              "First Name", "Last Name","SSN", "DOB", "Age", "Gender", "Relationship", "Benefit Type",
              "Plan Name", "HIOS ID", "Plan Metal Level", "Carrier Name",
              "Premium Amount", "Premium Total", "Policy APTC", "Responsible Premium Amt", "FPL",
              "Coverage Start", "Coverage End",
              "Home Address", "Mailing Address","Work Email", "Home Email", "Phone Number","Broker", "Broker NPN",
              "Race", "Ethnicity", "Citizen Status",
              "Broker Assisted"]
      while offset <= total_count
        enrollments.offset(offset).limit(batch_size).no_timeout.each do |enr|
          count += 1
          begin
            unless enr.subscriber.nil?
              next if enr.subscriber.person.blank?
              family = enr.family
              primary_person = family.primary_person
              primary_person_hbx_id = primary_person.hbx_id
              product = Caches::MongoidCache.lookup(BenefitMarkets::Products::Product, enr.product_id) do
                enr.product
              end
              enr.hbx_enrollment_members.each do |en|
                per = en.person
                premium_amount = (enr.is_ivl_by_kind? ? enr.premium_for(en) : (enr.decorated_hbx_enrollment.member_enrollments.find { |enrollment| enrollment.member_id == en.id }).product_price).to_f.round(2)
                next if per.blank?
                csv << [
                  primary_person_hbx_id, per.hbx_id, enr.hbx_id, enr.subscriber.hbx_id, enr.aasm_state,
                  member_status(enr),
                  per.first_name,
                  per.last_name,
                  per.ssn,
                  per.dob.strftime("%Y%m%d"),
                  per.age_on(enr.effective_on),
                  per.gender,
                  en.primary_relationship,
                  enr.coverage_kind,
                  product.name, product.hios_id, product.metal_level, product.carrier_profile.abbrev,
                  premium_amount, enr.total_premium, enr.applied_aptc_amount, total_responsible_amount(enr),
                  fpl_percentage(enr, en, enr.effective_on.year),
                  enr.effective_on.blank? ? nil : enr.effective_on.strftime("%Y%m%d"),
                  enr.terminated_on.blank? ? nil : enr.terminated_on.strftime("%Y%m%d"),
                  per.home_address&.full_address || enr.subscriber.person.home_address&.full_address,
                  per.mailing_address&.full_address || enr.subscriber.person.mailing_address&.full_address,
                  per.work_email&.address || enr.subscriber.person.work_email&.address,
                  per.home_email&.address || enr.subscriber.person.home_email&.address,
                  per.work_phone_or_best || enr.subscriber.person&.work_phone_or_best,
                  family.active_broker_agency_account&.writing_agent&.person&.full_name,
                  family.active_broker_agency_account&.writing_agent&.npn,
                  per.ethnicity,
                  ethnicity_status(per.ethnicity),
                  per.citizen_status,
                  broker_assisted(enr, primary_person)
                ]
              end
            end
          rescue StandardError => e
            puts "Unable to process enrollment #{enr.hbx_id} due to error #{e}"
          end
        end
        offset += batch_size
        puts "#{count}/#{total_count} done at #{Time.now}" if count % 10_000 == 0
        puts "#{count}/#{total_count} done at #{Time.now}" if count == total_count
      end
      puts "End of the report" unless Rails.env.test?
    end
  end
end
