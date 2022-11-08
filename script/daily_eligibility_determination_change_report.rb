# frozen_string_literal: true

require 'csv'
report_field_names = %w[First_Name
                        Last_Name
                        HBX_ID
                        IC_Number
                        Current_APTC_Max
                        New_APTC_Max
                        Current_CSR
                        New_CSR
                        Payload_Determination_Date
                        Current_Eligibility_Determination_Kind
                        New_Eligibility_Determination_Kind
                        Application_Year
                        Current_Plan_Name
                        Current_HIOS_ID
                        Current_Applied_APTC
                        Current_FPL_Amount]

logger_field_names = %w[Family_ID Backtrace]

report_file_name = "#{Rails.root}/daily_eligibility_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
logger_file_name = "#{Rails.root}/daily_eligibility_report_logger_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
previous_day = Time.now.getlocal.prev_day
start_on = ENV['start_on']
end_on = ENV['end_on']
start_time = start_on ? Time.parse(start_on).beginning_of_day.utc : previous_day.beginning_of_day.utc
end_time = end_on ? Time.parse(end_on).end_of_day.utc : previous_day.end_of_day.utc

source_mapper = { 'Renewals' => 'Renewals', 'Admin' =>  'Create Eligibility or Edit Aptc Csr', 'Curam' => 'Curam'}

# rubocop:disable Metrics/CyclomaticComplexity
def retrieve_csr(csr_values)
  return 'csr_0' if csr_values.include?('0')
  return 'csr_0' if csr_values.include?('limited') && (csr_values.include?('73') || csr_values.include?('87') || csr_values.include?('94'))
  return 'csr_limited' if csr_values.include?('limited')
  return 'csr_73' if csr_values.include?('73')
  return 'csr_87' if csr_values.include?('87')
  return 'csr_94' if csr_values.include?('94')
  return 'csr_100' if csr_values.include?('100')
  'csr_0'
end
# rubocop:enable Metrics/CyclomaticComplexity

def find_csr_value(family, tax_households)
  csr_hash = tax_households.map(&:tax_household_members).flatten.inject({}) do |result, member|
    result[member.applicant_id.to_s] = member.csr_percent_as_integer.to_s
    result
  end

  any_member_ia_not_eligible = family.family_members.any? { |family_member_id| csr_hash[family_member_id.to_s].nil? }

  if FinancialAssistanceRegistry.feature_enabled?(:native_american_csr)
    family.family_members.each do |family_member|
      csr_hash[family_member.id.to_s] = 'limited' if family_member.person.indian_tribe_member
    end
  end

  csr_values = csr_hash.values.uniq
  (any_member_ia_not_eligible || csr_values.blank?) ? 'csr_0' : retrieve_csr(csr_values)
end

CSV.open(logger_file_name, 'w', force_quotes: true) do |logger_csv|
  logger_csv << logger_field_names
  CSV.open(report_file_name, 'w', force_quotes: true) do |report_csv|
    report_csv << report_field_names
    if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
      families = Family.where(:'tax_household_groups' => {:"$elemMatch" => {:"created_at" => {:"$gte" => start_time, :"$lte" => end_time}, :"end_on" => nil}})
    else
      families = Family.where(:"households.tax_households.created_at" => { "$gte" => start_time, "$lte" => end_time})
    end

    families.inject(0) do |_dummy, family|
      primary_person = family.primary_person
      e_case_id = family.has_valid_e_case_id? ? family.e_case_id.split('#').last : 'N/A'
      active_statuses = %w[coverage_selected auto_renewing renewing_coverage_selected unverified]

      if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
        tax_household_group = family.tax_household_groups.where(:"created_at" => { "$gte" => start_time, "$lte" => end_time}, :"end_on" => nil).first
        tax_households = tax_household_group.tax_households
      else
        tax_households = family.active_household.tax_households
      end

      application_years = tax_households.map(&:effective_starting_on).map(&:year).uniq

      application_years.each do |year|
        active_enrollments = family.hbx_enrollments.by_year(year).individual_market.where(:aasm_state.in => active_statuses, coverage_kind: 'health')

        if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
          current_tax_household_group = family.tax_household_groups.where(:"end_on" => { "$gte" => start_time, "$lte" => end_time}).order_by(:created_at.desc).first
          current_tax_households = current_tax_household_group&.tax_households
          new_csr_percent = find_csr_value(family, tax_households)
          new_max_aptc = tax_households.sum { |thh| thh.max_aptc.to_f }
          new_csr_kind = source_mapper[tax_household_group.source] || tax_household_group.source || 'N/A'
          determined_at = tax_household_group.determined_on

          if current_tax_households.present?
            current_max_aptc = current_tax_households.sum { |thh| thh.max_aptc.to_f }
            current_csr_kind = source_mapper[current_tax_household_group&.source] || current_tax_household_group.source || 'N/A'
            current_csr_percent = find_csr_value(family, current_tax_households)

            thm = current_tax_households.map(&:tax_household_members).flatten.detect { |member| member.family_member_id.to_s == family.primary_family_member.id.to_s }
            thm_fpl_amount = thm.present? ? thm&.magi_as_percentage_of_fpl : 'N/A'
          end
        else
          new_thh = tax_households.tax_household_with_year(year).desc(:created_at).first
          new_ed = new_thh.latest_eligibility_determination
          new_csr_kind = source_mapper[new_ed.source]
          new_max_aptc = format('%.2f', new_ed.max_aptc.to_f)
          new_csr_percent = new_ed.csr_percent_as_integer
          determined_at = new_ed.determined_at
          current_thh = tax_households.tax_household_with_year(year).where(:id.ne => new_thh.id).desc(:created_at).first
          current_ed = current_thh&.latest_eligibility_determination
          current_max_aptc = current_ed&.max_aptc&.to_f.present? ? format('%.2f', current_ed.max_aptc.to_f) : 'N/A'
          current_csr_percent = current_ed&.csr_percent_as_integer.present? ? current_ed.csr_percent_as_integer.to_s : 'N/A'
          current_csr_kind = current_ed&.source.present? ? source_mapper[current_ed.source] : 'N/A'
          thm = current_thh&.tax_household_members&.detect { |member| member.family_member_id == family.primary_family_member.id }
          thm_fpl_amount = thm.present? ? thm&.magi_as_percentage_of_fpl : 'N/A'
        end

        if active_enrollments.present?
          active_enrollments.each do |enrollment|
            product = enrollment.product

            report_csv << [primary_person.first_name, primary_person.last_name,
                           primary_person.hbx_id, e_case_id, current_max_aptc,
                           new_max_aptc, current_csr_percent,
                           new_csr_percent, determined_at,
                           current_csr_kind, new_csr_kind,
                           year, product&.title, product&.hios_id,
                           enrollment&.applied_aptc_amount, thm_fpl_amount]
          end
        else
          report_csv << [primary_person.first_name, primary_person.last_name,
                         primary_person.hbx_id, e_case_id, current_max_aptc,
                         new_max_aptc, current_csr_percent,
                         new_csr_percent, determined_at,
                         current_csr_kind, new_csr_kind,
                         year, 'N/A', 'N/A', 'N/A', thm_fpl_amount]
        end
      end
    rescue StandardError => e
      logger_csv << [family.id, e.backtrace[0..5].join('\n')]
    end
  end
end
