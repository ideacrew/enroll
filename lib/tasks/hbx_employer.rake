require 'csv'

namespace :hbx do
  namespace :employers
    task :add do
      Employer = Struct.new(
          :app_response_code, :enroll_type, :complete_date, :user_name,
          :company_external_id, :fein, :dba, :legal_name, :previous_effective_date,
          :effective_date, :open_enrollment_start, :open_enrollment_end, 
          :poc_first_name, :poc_last_name, :poc_email, :poc_phone, 
          :census_count, :new_hire_wait_description, 
          :address_1, :address_2, :city, :state, :zip, :carrier_name,
          :locations,
          :broker_agency_id, :broker_first_name, :broker_last_name, :broker_email, :broker_external_id, :broker_npn, 
          :assign_enter_date, :assign_end_date
        )
    Location = Struct.new(
          :metal_selection, :plan_count, :reference_plan_name,:reference_plan_id, 
          :employee_contribution, :dependent_contribution, :name
      )

        def initialize (file_name) 
          @employers = []

          CSV.foreach(file_name, headers: true) do | row |
            @locations = [1..10].reduce([]) |collection, location| do
  
              defined?(base) ? base += 7 : base = 25 
              location = Location.new(
                  :metal_selection:         row[base + 0],
                  :plan_count:              row[base + 1].to_i,
                  :reference_plan_name:     row[base + 2],
                  :reference_plan_id:       row[base + 3].to_i,
                  :employee_contribution:   row[base + 4].to_i,
                  :dependent_contribution:  row[base + 5].to_i,
                  :name:                    row[base + 6]
                )
  
              collection << location
            end

            @employers << Employer.new(
                app_response_code:          row[0].to_i, 
                enroll_type:                row[1],               # initial or renewal
                complete_date:              Date.parse(row[2]), 
                user_name:                  row[3], 
                company_external_id:        row[4].to_i, 
                fein:                       row[5].to_s.gsub(/\D/, ''), 
                dba:                        row[6],
                legal_name:                 row[7],

                previous_effective_date:    row[8],
                effective_date:             Date.parse(row[9]),
                open_enrollment_start:      Date.parse(row[10]),
                open_enrollment_end:        Date.parse(row[11]),

                poc_first_name:             row[12],
                poc_last_name:              row[13],
                poc_email:                  row[14],
                poc_phone:                  row[15].to_s.gsub(/\D/, ''), 

                census_count:               row[16].to_i, 
                new_hire_wait_description:  row[17], 
                # "Date of Hire equal to Effective Date"
                # "First of the month following date of hire"
                # "First of the month following 30 days"
                # "First of the month following 60 days"

                address_1:                  row[18],
                address_2:                  row[19],
                city:                       row[20],
                state:                      row[21],
                zip:                        row[22],
                carrier_name:               row[23], # Aetna, CareFirst BlueCross BlueShield, Kaiser Permanente, UnitedHealthcare

                locations:                  @locations,

                broker_agency_id:    row[95].to_i,
                broker_first_name:   row[96],
                broker_last_name:    row[97],
                broker_email:        row[98],
                broker_external_id:  row[99].to_i,
                broker_npn:          row[100]to_i,
                assign_enter_date:   Date.parse(row[101]),
                assign_end_date:     Date.parse(row[102])
              )

          end 
        end
    end
  end
end

APPRESPONSECODE ENROLL_TYPE COMPLETEDDATE USERNAME  COMPANY_EXTERNAL_ID EIN DBA_NAME  LEGAL_NAME  PREVIOUS_EFFECTIVE_DATE 