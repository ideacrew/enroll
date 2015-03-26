require "tasks/hbx_employer_monkeypatch"

class HbxEmployerImport
  attr_reader :employer_file_name, :ignore_file_name, :plan_lookup_file_name

  def initialize(employer_file_name, ignore_file_name, plan_lookup_file_name)
    @employer_file_name = employer_file_name
    @ignore_file_name   = ignore_file_name
    @plan_lookup_file_name = plan_lookup_file_name
  end

  def run
    CSV.foreach(plan_lookup_file_name, headers: true) do |row|
      PlanLookup.add_from_row(row)
    end

    employers = []
    CSV.foreach(employer_file_name, headers: true) do |row|
      employers << Employer.from_row(row)
    end

    employers.sort_by! do |employer|
      [employer.fein, employer.user_name, employer.company_external_id, employer.complete_date]
    end
    # TODO: remove this, it is temporary to ensure the latest org instance is first
    employers.reverse!

    puts "Found #{employers.size} employers with #{employers.flat_map(&:locations).size} locations."

    @ignored_users = []
    CSV.foreach(ignore_file_name, headers: false) do | row |
      @ignored_users << row[0] if row[0].present?
    end
    @ignored_users.uniq!

    puts "Found #{@ignored_users.size} usernames to ignore."

    @ignored_users.each do |user|
      employers.delete_if {|employer| employer.user_name == user}
    end

    puts "Left with #{employers.size} employers with #{employers.flat_map(&:locations).size} locations."

    organizations = employers.collect(&:create_or_update_organization)

    found = employers.select do |employer|
      Organization.where("fein" => employer.fein).count > 0
    end

    puts "Found #{found.size} organizations."

    organizations_to_save = organizations.reject(&:persisted?)
    puts "Created #{organizations_to_save.size} new organizations."

    n_saved = organizations.reduce(0) do |acc, o|
      if o.valid? && !o.persisted?
        o.save
        if o.persisted?
          acc + 1
        else
          # TODO: error saving
          acc
        end
      else
        if o.valid?
          acc
        else
          #TODO: print errors?
          # puts "Error validating new organization:"
          # puts [o, o.office_locations, o.employer_profile, o.errors].collect(&:inspect)
          acc
        end
      end
    end

    puts "Successfully saved #{n_saved} new organizations."
  end
end

Employer = Struct.new(
    :app_response_code, :enroll_type, :complete_date, :user_name,
    :company_external_id, :fein, :dba, :legal_name,
    :previous_effective_date, :effective_date, :open_enrollment_start,
    :open_enrollment_end, :poc_first_name, :poc_last_name, :poc_email,
    :poc_phone, :census_count, :new_hire_wait_index,
    :new_hire_wait_description, :address_1,
    :address_2, :city, :state, :zip, :carrier_name, :locations,
    :broker_agency_id, :broker_first_name, :broker_last_name, :broker_email,
    :broker_external_id, :broker_npn, :assign_enter_date, :assign_end_date
) do
  def self.from_row(row)
    employer = Employer.new()
    employer.app_response_code           = row[0].to_i
    employer.enroll_type                 = row[1]
      # initial or renewal

    employer.complete_date               = row[2].to_date_safe
    employer.user_name                   = row[3]
    employer.company_external_id         = row[4].to_digits
    employer.fein                        = row[5].to_digits
    employer.dba                         = row[6]
    employer.legal_name                  = row[7]

    employer.previous_effective_date     = row[8]
    employer.effective_date              = row[9].to_date_safe
    employer.open_enrollment_start       = row[10].to_date_safe
    employer.open_enrollment_end         = row[11].to_date_safe

    employer.poc_first_name              = row[12]
    employer.poc_last_name               = row[13]
    employer.poc_email                   = row[14]
    employer.poc_phone                   = row[15].to_digits

    employer.census_count                = row[16].to_i
    employer.new_hire_wait_index         = row[17].to_i
    employer.new_hire_wait_description   = row[18]
      # "Date of Hire equal to Effective Date"
      # "First of the month following date of hire"
      # "First of the month following 30 days"
      # "First of the month following 60 days"

    employer.address_1                   = row[19]
    employer.address_2                   = row[20]
    employer.city                        = row[21]
    employer.state                       = row[22]
    employer.zip                         = row[23]
    employer.carrier_name                = row[24]
      # Aetna, CareFirst BlueCross BlueShield, Kaiser Permanente UnitedHealthcare
    employer.broker_agency_id            = row[95].to_i
    employer.broker_first_name           = row[96]
    employer.broker_last_name            = row[97]
    employer.broker_email                = row[98]
    employer.broker_external_id          = row[99].to_i
    employer.broker_npn                  = row[100].to_i
    employer.assign_enter_date           = row[101].to_date_safe
    employer.assign_end_date             = row[102].to_date_safe

    # columns 25 through 94 contain 10 locations of 7 fields each
    loc_index = 25
    loc_fields = 7
    n_locs = 10
    locations = (loc_index...(loc_index + (loc_fields * n_locs))).step(loc_fields).flat_map do |base|
      location_fields = [employer] + row.fields(base...(base + loc_fields))
      location = Location.from_row(*location_fields)
      location.present? ? location : []
    end
    employer.locations                   = locations

    employer
  end

  def create_or_update_organization
    # if organization exists compare with existing, and
    # update if this employer is the latest version
    o = Organization.where("fein" => fein).first
    if o
      # TODO: for each updateable field, update if new
    else
      o = Organization.new
      o.legal_name = legal_name
      o.dba = dba
      o.fein = fein
      o.is_active = true

      ol = o.office_locations.build

      ola = ol.build_address
      ola.kind = "work"
      ola.address_1 = address_1
      ola.address_2 = address_2
      ola.city = city
      ola.state = state
      ola.zip = zip

      olp = ol.build_phone
      olp.kind = "work"
      olp.full_phone_number = poc_phone

      oer = o.build_employer_profile
      oer.entity_kind = "c_corporation" # TODO: fix, this should probably come from the data

      py = oer.plan_years.build
      py.start_on = effective_date
      py.end_on = ((effective_date + 1.year) - 1.day).to_date
      py.open_enrollment_start_on = open_enrollment_start
      py.open_enrollment_end_on = open_enrollment_end
      py.fte_count = census_count

      locations.each do |loc|
        bg = loc.create_or_update_benefit_group(self, py)
      end

      # oer.broker_agency_id = broker_agency_id # TODO: fix, this isn't really our broker_agency_id
      # oer.

      # TODO: must save here because later rows might be updates to this employer
    end
    o
  end
end

Location = Struct.new(:employer,
      :metal_selection, :plan_count, :reference_plan_name,:reference_plan_id,
      :employee_contribution, :dependent_contribution, :name
) do
  def self.from_row(*args)
    if args[2].present?
      args = args.dup
      int_indexes = [2,4,5,6]
      int_indexes.each {|i| args[i] = args[i].to_i}
      Location.new(*args)
    end
  end

  def create_or_update_benefit_group(employer, plan_year)
    bg = plan_year.benefit_groups.build
    case employer.new_hire_wait_index
    when 1
      bg.effective_on_kind = "date_of_hire"
      bg.effective_on_offset = 0
    when 2
      bg.effective_on_kind = "first_of_month"
      bg.effective_on_offset = 0
    when 3
      bg.effective_on_kind = "first_of_month"
      bg.effective_on_offset = 30
    when 4
      bg.effective_on_kind = "first_of_month"
      bg.effective_on_offset = 60
    end
    bg.premium_pct_as_int = employee_contribution
    bg.employer_max_amt_in_cents = 0

    bg.title = name
    # TODO: figure out how to match plans
    bg.reference_plan = nil

    bg.benefit_list = BenefitGroup.simple_benefit_list(employee_contribution, dependent_contribution, 0)

    bg
  end
end

PlanLookup = Struct.new(:carrier_name, :hios_id, :mapping_id, :display_name, :metal,
                        :cert_start_on, :cert_end_on, :activation_start_on,
                        :activation_end_on
) do

  def plan

  end

  def self.add_from_row(row)
    lookup = PlanLookup.new
    lookup.carrier_name = row[1]
    lookup.hios_id = row[2]
    lookup.mapping_id = row[7]
    lookup.display_name = row[8]
    lookup.metal = row[11]
    lookup.cert_start_on = row[16].to_date_safe
    lookup.cert_end_on = row[17].to_date_safe
    lookup.activation_start_on = row[18].to_date_safe
    lookup.activation_end_on = row[19].to_date_safe
    lookups[[lookup.carrier_name, lookup.display_name]] = lookup
  end

  def self.lookup(carrier_name, plan_name)
    @lookups[[carrier_name, plan_name]]
  end

  private

  def self.lookups
    @lookups = {} if @lookups.nil?
    @lookups
  end
end
