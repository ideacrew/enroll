namespace :hbx_reports do
  namespace :vital_signs do

    desc "IVL Assisted Enrollment report"
    task assistance_eligible_families: :environment do
      families = Family.active_assistance_receiving.by_datetime_range(VitalSign::ZERO_HOUR, Time.now)

      # puts "Found #{families.size} families who qualified for assistance"
      puts "Found #{families.size} families"
      families.each do |family|
        subscriber = family.primary_family_member
        ed = family.latest_household.tax_households.first.eligibility_determinations.first
        enrollments = family.latest_household.hbx_enrollments.reduce([]) do |list, e|

          if e.plan.present?
            line_item = "  Type: #{e.plan.coverage_kind}, Plan: #{e.plan.name}, Premium: $#{e.total_premium}, Applied APTC: $#{e.applied_aptc_amount}, Effective: #{e.effective_on}, Submitted: #{e.submitted_at}"
          else
            line_item = "  Shopped, but plan not selected"
          end
          list << line_item
        end
        enrollments.uniq! if enrollments.present?

        puts "
Subscriber: #{subscriber.first_name} #{subscriber.last_name} 
Subscriber DCHL ID: #{subscriber.hbx_id}
Max APTC: $#{ed.max_aptc} 
CSR: #{ed.csr_percent_as_integer}%
Eligibility Determined: #{ed.determined_at} 
Enroll Received: #{ed.tax_household.created_at}
Curam IC/PDC: #{family.e_case_id.to_s.split('#').last} / #{ed.e_pdc_id}
Shopped?: #{enrollments.present? ? 'Yes' : 'No'}"

        enrollments.each {|e| puts e }
      end
    end

  end
end
