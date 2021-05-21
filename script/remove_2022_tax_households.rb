# This script is specific to ticket 94651, and is intended to remove one unintentionally added 2022 tax_household
require 'csv'

@slcsp = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.last.slcsp_id
@wrong_ssn_counter = 0

def start_date_of_next_year
  @start_date_of_next_year ||= TimeKeeper.date_of_record.next_year.beginning_of_year
end

def check_and_run
  not_run = []
  removed_households = []

  CSV.foreach("pids/#{start_date_of_next_year.year}_THHEligibility.csv") do |row_with_ssn|
    ssn, hbx_id, aptc, csr, date = row_with_ssn

    if aptc.blank? || csr.blank?
      not_run << {ssn: ssn, hbx_id: hbx_id, error: "Bad CSV data(csr/aptc)"}
      puts "Either aptc or csr are not valid"
      next
    end

    if ssn && ssn =~ /^\d+$/ && ssn.to_s != '0'
      ssn = '0'*(9-ssn.length) + ssn if ssn.length < 9
      person = Person.by_ssn(ssn).first rescue nil
    end

    person_by_hbx = Person.by_hbx_id(hbx_id).first rescue nil

    if ssn && hbx_id && person && person_by_hbx && person.id != person_by_hbx.id
      not_run << {ssn: ssn, hbx_id: hbx_id, error: "Bad CSV data(ssn/hbx_id)"}
      puts "Person with ssn: #{ssn} and person with hbx_id: #{hbx_id} are not same"
      next
    end

    person = person_by_hbx unless person

    if person
      unless person.primary_family
        not_run << {no_family: ssn, hbx_id: hbx_id}
        puts "Person with ssn: #{ssn} has no family"
        next
      end

      person.primary_family.active_household.tax_households.where(effective_starting_on: Date.new(2022,1,1)).each do |thh|
        thh.destroy!
      end
      removed_households << [person_hbx_id: person.hbx_id]
      puts "Removed tax household for person with person_hbx_id: #{person.hbx_id}"
    else
      not_run << {not_found: ssn}
      puts "Person with ssn: #{ssn} and hbx_id: #{hbx_id} can't be found."
    end

  end
  [not_run: {count: not_run.count, rs: not_run},
   removed_household: {count: removed_households.count, rs: removed_households}]
end

check_and_run
