require 'csv'
@pdc = 0
@slcsp = HbxProfile.current_hbx.benefit_sponsorship.benefit_coverage_periods.last.slcsp_id
@wrong_ssn_counter = 0

def check
  ran = []
  not_run = []
  CSV.foreach("spec/test_data/cne.csv") do |row|
    person = Person.by_hbx_id(row[0]).first
    deter = person.families.first.households.first.tax_households.where(effective_ending_on: nil).select{|x| x.effective_starting_on.year == 2017 }.first.try(:eligibility_determinations).try(:first)
    if deter && deter.e_pdc_id =~ /MANUALLY_9_2_2016LOADING/
      ran << row[0]
    else
      not_run << row[0]
    end
  end
  [ran, not_run]
end

def check_and_run
  ran = []
  not_run = []
  running = []

  CSV.foreach("spec/test_data/cne2.csv") do |row_with_ssn|
    person = Person.by_ssn(row_with_ssn.first).first
    if person
      deter = person.families.first.households.first.tax_households.where(effective_ending_on: nil).select{|x| x.effective_starting_on.year == 2017 }.first.try(:eligibility_determinations).try(:first)
      if deter && deter.e_pdc_id =~ /MANUALLY_9_2_2016LOADING/
        ran << row_with_ssn.first
      else
        hbx_id = person.hbx_id
        row=[hbx_id, row_with_ssn[1], row_with_ssn[2]]
        update_aptc(row)
        running << row_with_ssn.first
      end
    else
      not_run << row_with_ssn.first
      puts "Person with ssn: #{row_with_ssn.first} can't be found."
    end
  end

  [ran, not_run, running]
end


def update_aptc(row)
  person = Person.by_hbx_id(row[0]).first
  return unless person.primary_family
  @household = person.primary_family.active_household

  if @household.tax_households.present?
    latest_tax_household = @household.tax_households.where(effective_ending_on: nil).last
    latest_tax_household.update_attributes(effective_ending_on: Date.new(2016,12,31)) if latest_tax_household
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

  puts person.primary_family.active_household.tax_households.last.eligibility_determinations.inspect
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
