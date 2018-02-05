require 'csv'

@slcsp = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.last.slcsp_id
@wrong_ssn_counter = 0

def check_duplicated
  valid_people = {}
  dupes = {}
  not_found = []
  stranges = []

  CSV.foreach("pids/2018_THHEligibility.csv") do |row_with_ssn|
    ssn, hbx_id, aptc, csr, date = row_with_ssn
    if ssn && ssn =~ /^\d+$/ && ssn.to_s != '0'
      ssn = '0'*(9-ssn.length) + ssn if ssn.length < 9
      person = Person.by_ssn(ssn).first rescue nil
    end

    unless person
      person = Person.by_hbx_id(hbx_id).first rescue nil
    end

    if hbx_id.present? && person.present?
      person_by_hbx = Person.by_hbx_id(hbx_id).first rescue nil
      if person_by_hbx.present? && person_by_hbx.id != person.id
        stranges << {ssn: ssn, hbx_id: hbx_id}
        puts "Person with ssn: #{ssn} and hbx_id: #{hbx_id} is not the same one."
      end
    end

    if person.present?
      matched = valid_people[person.ssn]
      if matched
        matched_from_dupes = dupes[person.ssn]
        if matched_from_dupes
          dupes[person.ssn] += matched
        else
          dupes[person.ssn] = matched + [{ssn: ssn, hbx_id: hbx_id}]
        end
        puts "Person with ssn: #{ssn}, hbx_id: #{hbx_id} is duplicated."
      else
        valid_people[person.ssn] = [{ssn: ssn, hbx_id: hbx_id}]
      end
    else
      not_found << {ssn: ssn, hbx_id: hbx_id}
      puts "Person with ssn: #{ssn} can't be found."
    end
  end
  {dupes: {count: dupes.values.map(&:count).inject(&:+), rs: dupes},
   mismatched: {count: stranges.count, rs: stranges},
   not_found: {count: not_found.count, rs: not_found}}
end

def check_and_run
  ran = []
  not_run = []
  running = []

  CSV.foreach("pids/2018_THHEligibility.csv") do |row_with_ssn|
    ssn, hbx_id, aptc, csr, date = row_with_ssn

    effective_date = date.to_date

    if ssn && ssn =~ /^\d+$/ && ssn.to_s != '0'
      ssn = '0'*(9-ssn.length) + ssn if ssn.length < 9
      person = Person.by_ssn(ssn).first rescue nil
    end

    unless person
      person = Person.by_hbx_id(hbx_id).first rescue nil
    end

    if person
      unless person.primary_family
        not_run << {no_family: ssn, hbx_id: hbx_id}
        puts "Person with ssn: #{ssn} has no family"
        next
      end

      active_household = person.primary_family.active_household
      active_thh = active_household.latest_active_thh_with_year(effective_date.year)
      deter = active_thh.try(:latest_eligibility_determination)

      if active_thh && deter.present? && deter.csr_percent_as_integer.to_s == csr && active_thh.effective_starting_on.to_date == effective_date && deter.max_aptc.to_f == aptc.to_f
        not_run << [hbx_id: person.hbx_id, error: 'active THH with eligibility having same aptc, csr & thh_effective_date is already present']
      else
        active_household.build_thh_and_eligibility(aptc, csr, effective_date, @slcsp)
        running << [hbx_id: person.hbx_id]
      end

    else
      not_run << {not_found: ssn}
      puts "Person with ssn: #{ssn} can't be found."
    end

  end
  [ran: {count: ran.count, rs: ran},
   not_run: {count: not_run.count, rs: not_run},
   running: {count: running.count, rs: running}]
end