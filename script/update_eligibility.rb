require 'csv'
@pdc = 0
@slcsp = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.last.slcsp_id
@wrong_ssn_counter = 0

def check
  ran = []
  running = []
  CSV.foreach("spec/test_data/cne.csv") do |row|
    person = Person.by_hbx_id(row[0]).first
    deter = person.primary_family.active_household.latest_active_tax_household_with_year(2017).try(:latest_eligibility_determination)
    if deter && deter.e_pdc_id =~ /MANUALLY_9_2_2016LOADING/
      ran << row[0]
      print 'r'
    else
      update_aptc(row)
      running << row[0]
      print 'i'
    end
  end
  [ran: {count: ran.count, rs: ran},
   running: {count: running.count, rs: running}]
end

def check3_and_run
  ran = []
  not_run = []
  running = []

  CSV.foreach("spec/test_data/cne3.csv") do |row_with_ssn|
    ssn, hbx_id, aptc, csr = row_with_ssn
    if ssn && ssn =~ /^\d+$/ && ssn.to_s != '0'
      person = Person.by_ssn(ssn).first rescue nil
    end

    unless person
      person = Person.by_hbx_id(hbx_id).first rescue nil
    end

    if person
      unless person.primary_family
        not_run << {no_family: ssn}
        puts "Person with ssn: #{ssn} has no family."
        next
      end
      deter = person.primary_family.active_household.latest_active_tax_household_with_year(2017).try(:latest_eligibility_determination)
      if deter && deter.e_pdc_id =~ /MANUALLY_9_2_2016LOADING/
        ran << person.hbx_id
        print 'r'
      else
        row=[person.hbx_id, aptc, csr]
        update_aptc(row)
        running << person.hbx_id
        print '#'
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

def check2_and_run
  ran = []
  not_run = []
  running = []

  CSV.foreach("spec/test_data/cne2.csv") do |row_with_ssn|
    person = Person.by_ssn(row_with_ssn.first).first
    if person
      unless person.primary_family
        not_run << row_with_ssn.first
        print 'n'
        next
      end
      deter = person.primary_family.active_household.latest_active_tax_household_with_year(2017).try(:latest_eligibility_determination)
      if deter && deter.e_pdc_id =~ /MANUALLY_9_2_2016LOADING/
        ran << row_with_ssn.first
        print 'r'
      else
        hbx_id = person.hbx_id
        row=[hbx_id, row_with_ssn[1], row_with_ssn[2]]
        update_aptc(row)
        running << row_with_ssn.first
        print 'i'
      end
    else
      not_run << row_with_ssn.first
      print 'n'
      #puts "Person with ssn: #{row_with_ssn.first} can't be found."
    end
  end

  [ran: {count: ran.count, rs: ran},
   not_run: {count: not_run.count, rs: not_run},
   running: {count: running.count, rs: running}]
end


def update_aptc(row)
  person = Person.by_hbx_id(row[0]).first
  return unless person.primary_family
  @household = person.primary_family.active_household

  if @household.tax_households.present?
    active_tax_households = @household.tax_households.active_tax_household
    active_tax_households.update_all(effective_ending_on: Date.new(2016,12,31)) if active_tax_households
  end

  th = @household.tax_households.build(
    allocated_aptc: 0.0,
    effective_starting_on: Date.new(2017,1,1),
    is_eligibility_determined: true,
    submitted_at: Date.today
  )

  th.tax_household_members.build(
    family_member: @household.family.primary_family_member,
    is_subscriber: true,
    is_ia_eligible: true,
  )

  @pdc+=1

  th.eligibility_determinations.build(
    e_pdc_id: "MANUALLY_9_2_2016LOADING" + @pdc.to_s,
    benchmark_plan_id: @slcsp,
    max_aptc: row[1],
    csr_percent_as_integer: row[2],
    determined_on: Date.today
  )

  th.save!

  person.primary_family.dependents.each do |fm|
    th = @household.latest_active_tax_household
    th.tax_household_members.build(
      family_member: fm,
      is_subscriber: false,
      is_ia_eligible: true
      )
    th.save!
  end

  #puts person.primary_family.active_household.tax_households.last.eligibility_determinations.inspect
end

def run
  CSV.foreach("spec/test_data/cne.csv") do |row|
    update_aptc(row)
  end

  CSV.foreach("spec/test_data/cne2.csv") do |row_with_ssn|
    person = Person.by_ssn(row_with_ssn.first).first
    if person
      hbx_id = person.hbx_id
      row=[hbx_id, row_with_ssn[1], row_with_ssn[2]]
      update_aptc(row)
    else
      @wrong_ssn_counter += 1
      puts "Person with ssn: #{row_with_ssn.first} can't be found."
    end
  end

  puts "#{@wrong_ssn_counter} people can't be found by SSN" if @wrong_ssn_counter > 0
end
