class HbxEmployerImport
  attr_reader :employer_file_name, :ignore_file_name

  def initialize(employer_file_name, ignore_file_name)
    @employer_file_name = employer_file_name
    @ignore_file_name   = ignore_file_name
  end

  def run
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

Location = Struct.new(
      :metal_selection, :plan_count, :reference_plan_name,:reference_plan_id,
      :employee_contribution, :dependent_contribution, :name
)

Location.class_eval do
  def self.from_row(*args)
    if args[2].present?
      args = args.dup
      int_indexes = [1,3,4,5]
      int_indexes.each {|i| args[i] = args[i].to_i}
      Location.new(*args)
    end
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
)

Employer.class_eval do
  def self.from_row(row)
    # columns 25 through 94 contain 10 locations of 7 fields each
    loc_index = 25
    loc_fields = 7
    n_locs = 10
    locations = (loc_index...(loc_index + (loc_fields * n_locs))).step(loc_fields).flat_map do |base|
      location_fields = row.fields(base...(base + loc_fields))
      location = Location.from_row(*location_fields)
      location.present? ? location : []
    end

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
    employer.locations                   = locations
    employer.broker_agency_id            = row[95].to_i
    employer.broker_first_name           = row[96]
    employer.broker_last_name            = row[97]
    employer.broker_email                = row[98]
    employer.broker_external_id          = row[99].to_i
    employer.broker_npn                  = row[100].to_i
    employer.assign_enter_date           = row[101].to_date_safe
    employer.assign_end_date             = row[102].to_date_safe
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
      # oer.broker_agency_id = broker_agency_id # TODO: fix, this isn't really our broker_agency_id
      # oer.

      # TODO: must save here because later rows might be updates to this employer
    end
    o
  end
end

String.class_eval do
  def to_digits
    self.gsub(/\D/, '')
  end

  def to_date_safe
    date = nil
    unless self.blank?
      begin
        date = Date.parse(self)
      rescue
        begin
          date = Date.strptime(self, '%m/%d/%Y')
        rescue Exception => e
          puts "There was an error parsing {#{self}} as a date."
        end
      end
    end
    date
  end
end

Object.class_eval do
  def to_digits
    self.to_s.to_digits
  end

  def to_date_safe
    self.to_s.to_date_safe
  end
end
