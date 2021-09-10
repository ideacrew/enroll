require 'csv'

@slcsp = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.last.slcsp_id
@wrong_ssn_counter = 0

def start_date_of_next_year
  @start_date_of_next_year ||= TimeKeeper.date_of_record.next_year.beginning_of_year
end

def check_and_run
  report_name = "#{Rails.root}/eligibilities_not_updated_list_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
  field_names = %w(
          person_ssn
          person_hbx_id
          primary_hbx_id
          message
        )

  CSV.open(report_name, "w", force_quotes: true) do |csv|
    csv << field_names

    ran = []
    updated_member_csr = []
    not_run = []
    created_eligibility = []

    CSV.foreach("pids/#{start_date_of_next_year.year}_THHEligibility.csv") do |row_with_ssn|
      person_ssn, person_hbx_id, primary_hbx_id, aptc, csr, date = row_with_ssn
      date ||= start_date_of_next_year.to_s
      effective_date = date.to_date

      if aptc.blank? || csr.blank?
        not_run << {ssn: person_ssn, primary_hbx_id: primary_hbx_id, person_hbx_id: person_hbx_id, error: "Bad CSV data(csr/aptc)"}
        csv << [person_ssn, person_hbx_id, primary_hbx_id, "APTC or CSR value invalid"]
        next
      end

      if person_ssn && person_ssn =~ /^\d+$/ && person_ssn.to_s != '0'
        person_ssn = '0'*(9-person_ssn.length) + person_ssn if person_ssn.length < 9
        person = Person.by_ssn(person_ssn).first rescue nil
      end

      primary_person_by_hbx = Person.by_hbx_id(primary_hbx_id).first rescue nil
      person_by_hbx = Person.by_hbx_id(person_hbx_id).first rescue nil

      if person_ssn && person && person_by_hbx && person.id != person_by_hbx.id
        not_run << {person_ssn: person_ssn, hbx_id: person_hbx_id, error: "Bad CSV data(person_ssn/hbx_id)"}
        csv << [person_ssn, person_hbx_id, primary_hbx_id, "Person with ssn: #{person_ssn} and person with hbx_id: #{person_hbx_id} are not same"]
        next
      end

      primary_person = primary_person_by_hbx unless primary_person
      person = person_by_hbx unless person
      if primary_person
        primary_family = primary_person.primary_family
        unless primary_family
          not_run << {person_hbx_id: person.hbx_id, primary_hbx_id: primary_hbx_id}
          csv << [person_ssn, person_hbx_id, primary_hbx_id, "Family not found for primary person with hbx_id: #{primary_hbx_id} when processing for person hbx_id: #{person_hbx_id}"]
          next
        end
      else
        not_run << {error: 'did not find the primary family for the primary person with hbx_id #{primary_hbx_id}'}
        csv << [person_ssn, person_hbx_id, primary_hbx_id, "Could not create eligibility or update individual csr for #{person_hbx_id}"]
        next
      end

      active_household = primary_family.active_household
      active_thh = active_household.latest_active_thh_with_year(effective_date.year)
      deter = active_thh.try(:latest_eligibility_determination)

      if active_thh && deter.present? && active_thh.effective_starting_on.to_date == effective_date && deter.max_aptc.to_f == aptc.to_f
        csr_int = (csr == 'limited' ? '-1' : csr)
        person_fm = primary_family.family_members.active.where(person_id: person.id)
        unless person_fm.empty?
          person_fm_id = person_fm.first.id
          person_thhm = active_thh.tax_household_members.where(applicant_id: person_fm_id).first
          person_thhm.update_attributes!(csr_percent_as_integer: csr_int)
          updated_member_csr << [hbx_id: person.hbx_id, message: 'active THH with eligibility having same aptc, csr & thh_effective_date is already present and updated the individual CSR']
          csv << [person_ssn, person_hbx_id, primary_hbx_id, "Updated individual csr for member with person hbx_id #{person.hbx_id} as this household already has one under the family for primary #{primary_person.hbx_id}"]
        else
          not_run << {person_hbx_id: person.hbx_id, primary_hbx_id: person_hbx_id}
          csv << [person_ssn, person_hbx_id, primary_hbx_id, "Dependent person with hbx_id: #{primary_hbx_id} not found in family for primary person hbx_id: #{primary_hbx_id}"]
          next
        end
      else
        active_household.build_thh_and_eligibility(aptc, csr, effective_date, @slcsp, 'Renewals') #update attrs here?
        created_eligibility << [primary_hbx_id: primary_person.hbx_id, person_hbx_id: person_hbx_id]
        csv << [person_ssn, person_hbx_id, primary_hbx_id, "Created Eligibility for family with primary_person_hbx_id: #{primary_person.hbx_id} and given csr for all members with #{csr}"]
      end

    end
    [ran: {count: ran.count, rs: ran},
     not_run: {count: not_run.count, rs: not_run},
     updated_member_csr: {count: updated_member_csr.count, rs: updated_member_csr},
     created_eligibility: {count: created_eligibility.count, rs: created_eligibility}]
  end
end
