require 'csv'

namespace :hbx do
  namespace :employers do
    task :add do
      Employer = Struct.new(
          :app_response_code, :enroll_type, :complete_date, :user_name,
          :company_external_id, :fein, :dba, :legal_name,
          :previous_effective_date, :effective_date, :open_enrollment_start,
          :open_enrollment_end, :poc_first_name, :poc_last_name, :poc_email,
          :poc_phone, :census_count, :new_hire_wait_description, :address_1,
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

      def initialize (file_name)
        @employers = []

        CSV.foreach(file_name, headers: true) do | row |
          # columns 24 through 93 contain 10 locations of 7 fields each
          loc_index = 24
          loc_fields = 7
          n_locs = 10
          @locations = (loc_index...(loc_fields * n_locs)).step(n_locs).flatmap do |base|
            location = Location.from_row(*row[base...(base + n_locs)])
          end

          new_employer = Employer.new()
          new_employer.app_response_code           = row[0].to_i
          new_employer.enroll_type                 = row[1]               # initial or renewal
          new_employer.complete_date               = Date.parse(row[2])
          new_employer.user_name                   = row[3]
          new_employer.company_external_id         = row[4].to_i
          new_employer.fein                        = row[5].to_s.gsub(/\D/, '')
          new_employer.dba                         = row[6]
          new_employer.legal_name                  = row[7]

          new_employer.previous_effective_date     = row[8]
          new_employer.effective_date              = Date.parse(row[9])
          new_employer.open_enrollment_start       = Date.parse(row[10])
          new_employer.open_enrollment_end         = Date.parse(row[11])

          new_employer.poc_first_name              = row[12]
          new_employer.poc_last_name               = row[13]
          new_employer.poc_email                   = row[14]
          new_employer.poc_phone                   = row[15].to_s.gsub(/\D/, '')

          new_employer.census_count                = row[16].to_i
          new_employer.new_hire_wait_description   = row[17]
              # "Date of Hire equal to Effective Date"
              # "First of the month following date of hire"
              # "First of the month following 30 days"
              # "First of the month following 60 days"

          new_employer.address_1                   = row[18]
          new_employer.address_2                   = row[19]
          new_employer.city                        = row[20]
          new_employer.state                       = row[21]
          new_employer.zip                         = row[22]
          new_employer.carrier_name                = row[23], # Aetna, CareFirst BlueCross BlueShield, Kaiser Permanente UnitedHealthcare
          new_employer.locations                   = @locations
          new_employer.broker_agency_id            = row[94].to_i
          new_employer.broker_first_name           = row[95]
          new_employer.broker_last_name            = row[96]
          new_employer.broker_email                = row[97]
          new_employer.broker_external_id          = row[98].to_i
          new_employer.broker_npn                  = row[99].to_i
          new_employer.assign_enter_date           = Date.parse(row[100])
          new_employer.assign_end_date             = Date.parse(row[101])
          @employers << new_employer
        end
      end
    end
  end
end
