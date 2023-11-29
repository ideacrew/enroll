require 'csv'

@slcsp = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.last.slcsp_id
@wrong_ssn_counter = 0

def start_date_of_next_year
  @start_date_of_next_year ||= TimeKeeper.date_of_record.next_year.beginning_of_year
end

report_name = "#{Rails.root}/eligibilities_updated_list_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
field_names = %w(
        primary_ssn
        primary_hbx_id
        message
      )

eligibility_file_name = "#{Rails.root}/eligibilities/#{start_date_of_next_year.year}_THHEligibility.csv"

CSV.open(report_name, "w", force_quotes: true) do |csv|
  csv << field_names

  ran = 0
  updated_member_csr = 0
  not_run = 0
  created_eligibility = 0

  CSV.foreach(eligibility_file_name) do |row_with_ssn|
    primary_ssn, primary_hbx_id, aptc, date, individual_csr = row_with_ssn
    # ignore input date in case of bad formatting; effective date will always be start_date_of_next_year for renewals
    effective_date = start_date_of_next_year

    if aptc.blank?
      not_run += 1
      csv << [primary_ssn, primary_hbx_id, "APTC value invalid"]
      next
    end

    if primary_ssn && primary_ssn =~ /^\d+$/ && primary_ssn.to_s != '0'
      primary_ssn = '0'*(9-primary_ssn.length) + primary_ssn if primary_ssn.length < 9
      primary_person = Person.by_ssn(primary_ssn).first rescue nil
    end

    primary_person_by_hbx = Person.by_hbx_id(primary_hbx_id).first rescue nil

    if primary_ssn && primary_person && primary_person_by_hbx && primary_person.id != primary_person_by_hbx.id
      not_run += 1
      csv << [primary_ssn, primary_person_by_hbx, "Person with ssn: #{primary_ssn} and person with hbx_id: #{primary_person_by_hbx} are not same"]
      next
    end

    primary_person = primary_person_by_hbx unless primary_person

    if primary_person
      primary_family = primary_person.primary_family
      unless primary_family
        not_run += 1
        csv << [primary_ssn, primary_hbx_id, "Family not found for primary person with hbx_id: #{primary_hbx_id}"]
        next
      end
    else
      not_run += 1
      csv << [primary_ssn, primary_hbx_id, "Could not create eligibility or update individual csr for #{primary_hbx_id}"]
      next
    end

    active_household = primary_family.active_household
    active_thh = active_household.latest_active_thh_with_year(effective_date.year)
    deter = active_thh.try(:latest_eligibility_determination)

    individual_csr.gsub!("'", "\"")
    csr_hash = JSON.parse(individual_csr)
    if active_thh && deter.present? && active_thh.effective_starting_on.to_date == effective_date && deter.max_aptc.to_f == aptc.to_f
      csr_hash.keys.each do |person_hbx_id|
        person = Person.where(hbx_id: person_hbx_id).first # what happens when there is no person record or multiple person with same hbx_id
        csr_int = csr_hash[person_hbx_id]
        csr_int = (csr_int == 'limited' ? '-1' : csr_int)
        person_fm = primary_family.family_members.active.where(person_id: person.id) if person.present?
        if person_fm.present?
          person_fm_id = person_fm.first.id
          person_thhm = active_thh.tax_household_members.where(applicant_id: person_fm_id).first
          next if person_thhm.csr_percent_as_integer == csr_int.to_i
          person_thhm.update_attributes!(csr_percent_as_integer: csr_int)
          deter.update_attributes!(source: 'Renewals')
          ran += 1
          updated_member_csr += 1
          csv << [primary_ssn, person_hbx_id, primary_hbx_id, "Updated individual csr for member with person hbx_id #{person.hbx_id} as this household already has one under the family for primary #{primary_person.hbx_id}"]
        else
          not_run += 1
          csv << [primary_ssn, person_hbx_id, primary_hbx_id, "Dependent person with hbx_id: #{person_hbx_id} not found in family for primary person hbx_id: #{primary_hbx_id}"]
          next
        end
      end
    else
      puts "Creating eligibility for family with primary_person_hbx_id: #{primary_person.hbx_id}"
      active_household.build_thh_and_eligibility(aptc, 0, effective_date, @slcsp, 'Renewals', csr_hash) # send 0 csr as default
      ran += 1
      created_eligibility += 1
      csv << [primary_ssn, primary_hbx_id, "Created Eligibility for family with primary_person_hbx_id: #{primary_person.hbx_id}"]
    end

  end
  puts "SUMMARY: #{[ran: ran, not_run: not_run, updated_member_csr: updated_member_csr, created_eligibility: created_eligibility]}"
end
