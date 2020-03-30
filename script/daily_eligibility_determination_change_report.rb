# frozen_string_literal: true

require 'csv'
field_names = %w[First_Name
                 Last_Name
                 HBX_ID
                 IC_Number
                 Current_APTC_max
                 New_APTC_max
                 Current_CSR
                 New_CSR
                 Payload_Determination_Date
                 Current_Eligibility_Determination_Kind
                 New_Eligibility_Determination_Kind
                 Application_Year
                 Current_Plan_Name
                 Current_HIOS_ID
                 Current_applied_APTC]

file_name = "#{Rails.root}/daily_eligibility_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
previous_day = Time.now.getlocal.prev_day
start_time = previous_day.beginning_of_day.utc
end_time = previous_day.end_of_day.utc

CSV.open(file_name, 'w', force_quotes: true) do |csv|
  csv << field_names
  families = Family.where(:"households.tax_households.created_at" => { "$gte" => start_time, "$lte" => end_time})
  families.inject(0) do |_dummy, family|
    primary_person = family.primary_person
    e_case_id = family.has_valid_e_case_id? ? family.e_case_id.split('#').last : 'N/A'
    tax_households = family.active_household.tax_households
    thhs_created_yesterday = tax_households.where(:created_at => {"$gte" => start_time, "$lte" => end_time})
    application_years = thhs_created_yesterday.map(&:effective_starting_on).map(&:year).uniq
    active_statuses = %w[coverage_selected auto_renewing renewing_coverage_selected unverified]
    application_years.each do |year|
      active_enrollments = family.hbx_enrollments.by_year(year).individual_market.where(:aasm_state.in => active_statuses, coverage_kind: 'health')
      new_thh = thhs_created_yesterday.tax_household_with_year(year).desc(:created_at).first
      new_ed = new_thh.latest_eligibility_determination
      current_thh = tax_households.tax_household_with_year(year).where(:id.ne => new_thh.id).desc(:created_at).first
      current_ed = current_thh&.latest_eligibility_determination

      if active_enrollments.present?
        active_enrollments.each do |enrollment|
          csv << [primary_person.first_name, primary_person.last_name,
                  primary_person.hbx_id, e_case_id, current_ed&.max_aptc&.to_f,
                  new_ed.max_aptc.to_f, current_ed&.csr_percent_as_integer,
                  new_ed.csr_percent_as_integer, new_ed.determined_on,
                  current_ed&.csr_eligibility_kind, new_ed.csr_eligibility_kind,
                  year, enrollment.product&.title, enrollment.product&.hios_id,
                  enrollment&.applied_aptc_amount]
        end
      else
        csv << [primary_person.first_name, primary_person.last_name,
                primary_person.hbx_id, e_case_id, current_ed&.max_aptc&.to_f,
                new_ed.max_aptc.to_f, current_ed&.csr_percent_as_integer,
                new_ed.csr_percent_as_integer, new_ed.determined_on,
                current_ed&.csr_eligibility_kind, new_ed.csr_eligibility_kind,
                year, 'N/A', 'N/A', 'N/A']
      end
    end
  rescue StandardError => e
    puts e.message
  end
end
