require 'csv'

namespace :hbx do
  namespace :employers do
    task :add, [:employee_file_name, :ignore_file_name] => [:environment] do |t, args|
      employee_file_name = args[:employee_file_name]
      ignore_file_name = args[:ignore_file_name]

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

      Location = Struct.new(
            :metal_selection, :plan_count, :reference_plan_name,:reference_plan_id,
            :employee_contribution, :dependent_contribution, :name
      )

      def Location.from_row(*args)
        if args[2].present?
          args = args.dup
          int_indexes = [1,3,4,5]
          int_indexes.each {|i| args[i] = args[i].to_i}
          Location.new(*args)
        end
      end

      def parse_date_safe(field)
        date = nil
        if field.present?
          begin
            date = Date.parse(field)
          rescue
            begin
              date = Date.strptime(field, '%m/%d/%Y')
            rescue Exception => e
              puts "There was an error parsing {#{field}} as a date."
            end
          end
        end
        date
      end

      employers = []

      CSV.foreach(employee_file_name, headers: true) do | row |
        # columns 25 through 94 contain 10 locations of 7 fields each
        loc_index = 25
        loc_fields = 7
        n_locs = 10
        locations = (loc_index...(loc_index + (loc_fields * n_locs))).step(loc_fields).flat_map do |base|
          location_fields = row.fields(base...(base + loc_fields))
          location = Location.from_row(*location_fields)
          location.present? ? location : []
        end

        new_employer = Employer.new()
        new_employer.app_response_code           = row[0].to_i
        new_employer.enroll_type                 = row[1]
          # initial or renewal

        new_employer.complete_date               = parse_date_safe(row[2])
        new_employer.user_name                   = row[3]
        new_employer.company_external_id         = row[4].to_i
        new_employer.fein                        = row[5].to_s.gsub(/\D/, '')
        new_employer.dba                         = row[6]
        new_employer.legal_name                  = row[7]

        new_employer.previous_effective_date     = row[8]
        new_employer.effective_date              = parse_date_safe(row[9])
        new_employer.open_enrollment_start       = parse_date_safe(row[10])
        new_employer.open_enrollment_end         = parse_date_safe(row[11])

        new_employer.poc_first_name              = row[12]
        new_employer.poc_last_name               = row[13]
        new_employer.poc_email                   = row[14]
        new_employer.poc_phone                   = row[15].to_s.gsub(/\D/, '')

        new_employer.census_count                = row[16].to_i
        new_employer.new_hire_wait_index         = row[17].to_i
        new_employer.new_hire_wait_description   = row[18]
          # "Date of Hire equal to Effective Date"
          # "First of the month following date of hire"
          # "First of the month following 30 days"
          # "First of the month following 60 days"

        new_employer.address_1                   = row[19]
        new_employer.address_2                   = row[20]
        new_employer.city                        = row[21]
        new_employer.state                       = row[22]
        new_employer.zip                         = row[23]
        new_employer.carrier_name                = row[24]
          # Aetna, CareFirst BlueCross BlueShield, Kaiser Permanente UnitedHealthcare
        new_employer.locations                   = locations
        new_employer.broker_agency_id            = row[95].to_i
        new_employer.broker_first_name           = row[96]
        new_employer.broker_last_name            = row[97]
        new_employer.broker_email                = row[98]
        new_employer.broker_external_id          = row[99].to_i
        new_employer.broker_npn                  = row[100].to_i
        new_employer.assign_enter_date           = parse_date_safe(row[101])
        new_employer.assign_end_date             = parse_date_safe(row[102])
        employers << new_employer
      end

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

      employers.uniq!

      puts "Left with #{employers.size} employers with #{employers.flat_map(&:locations).size} locations."

      organizations = []
      employers.each do |er|
        o = Organization.where("fein" => er.fein)
        unless o.present?
          o = Organization.new
          o.legal_name = er.legal_name
          o.dba = er.dba
          o.fein = er.fein
          o.is_active = true

          ol = o.office_locations.build

          ola = ol.build_address
          ola.kind = "work"
          ola.address_1 = er.address_1
          ola.address_2 = er.address_2
          ola.city = er.city
          ola.state = er.state
          ola.zip = er.zip

          olp = ol.build_phone
          olp.kind = "work"
          olp.full_phone_number = er.poc_phone

          oer = o.build_employer_profile
          oer.entity_kind = "c_corporation" # TODO: fix, this should probably come from the data
          # oer.broker_agency_id = er.broker_agency_id # TODO: fix, this isn't really our broker_agency_id
          # oer.
          organizations << o
        end
      end

      found = employers.select do |employer|
        Organization.where("fein" => employer.fein).present?
      end

      puts "Found #{found.size} organizations."

      puts "Created #{organizations.size} new organizations."

      n_saved = organizations.reduce(0) do |acc, o|
        o.save
        if o.valid?
          acc + 1
        else
          #TODO: print errors?
          acc
        end
      end

      puts "Successfully saved #{n_saved} new organizations."
    end
  end
end
