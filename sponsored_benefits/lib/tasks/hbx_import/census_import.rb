require "tasks/hbx_import/employer_monkeypatch"

module HbxImport
  class CensusImport
    attr_reader :file_name

    def initialize(file_name)
      @file_name = file_name
    end

    def run
      census_employees_from_csv = []
      CSV.foreach(file_name, headers: true) do |row|
        census_employees_from_csv << CensusRecord.from_row(row.fields)
      end
      census_employees_from_csv = census_employees_from_csv.reject(&:nil?).sort.uniq
      puts "Found #{census_employees_from_csv.size} unique census records in #{census_employees_from_csv.collect(&:fein).uniq.size} employers."

      census_employees_grouped = census_employees_from_csv.group_by{|census_employee| census_employee.fein}

      census_employees_to_save = []
      benefit_groups_to_save = []
      census_employees_grouped.each do |fein, census_employees|
        employer_profile = EmployerProfile.find_by_fein(fein)
        if employer_profile.present?
          plan_year = employer_profile.plan_years.last
          benefit_group = plan_year.benefit_groups.last
          census_employees.each do |census_employee|
            found = CensusEmployee.where(ssn: census_employee.ssn, dob: census_employee.dob).to_a.first
            if found.nil?
              ce = CensusEmployee.new
              ce.first_name = census_employee.first_name
              ce.last_name = census_employee.last_name
              ce.ssn = census_employee.ssn
              ce.dob = census_employee.dob
              ce.gender = census_employee.gender
              ce.is_business_owner = false
              ce.hired_on = census_employee.doh
              ce.employer_profile = employer_profile
              if !census_employee.work_email.blank?
                ce.build_email(kind: "work", address: census_employee.work_email)
              end
#              ce.build_address(kind: "home",address_1:"830 I St NE",city:"Washington",state:"DC",zip:"20002")
              ce.employment_terminated_on = census_employee.dot
              ce.add_benefit_group_assignment(benefit_group, plan_year.start_on)
              begin
              ce.save!
              if !ce.employment_terminated_on.blank?
                ce.aasm_state = "employment_terminated"
                ce.save!
              end
              benefit_group.census_employees << ce._id

              census_employees_to_save << ce
              rescue
                puts census_employee.work_email.inspect
                puts ce.errors.inspect
              end
            end
          end
        end
      end

      puts "Built #{census_employees_to_save.count} new census records."

      save_status = census_employees_to_save.reduce(
        saved_census_employees: [],
        saved_benefit_groups: [],
        failed_census_employees: [],
        failed_benefit_groups: []
      ) do |status, employee|
        employee.save
        if employee.valid?
          status[:saved_census_employees] << employee
          employee.active_benefit_group_assignment.save
          if employee.active_benefit_group_assignment.valid?
            status[:saved_benefit_groups] << employee.active_benefit_group_assignment
          else
            status[:failed_benefit_groups] << employee.active_benefit_group_assignment
          end
        else
          status[:failed_census_employees] << employee
        end
        status
      end

      puts "Successfully saved #{save_status[:saved_census_employees].count} new census records."
      puts "Successfully saved #{save_status[:saved_benefit_groups].count} benefit group members."
    end
  end

  CensusRecord = Struct.new(
    :dba, :fein, :first_name, :last_name, :ssn, 
    :dob, :doh, :dot, :work_email,
    :person_email, :individual_external_id, :employee_external_id,
    :record_start_date, :record_end_date, :gender
  ) do
    include Comparable

    def self.set_last_order(recipient, another)
      @recipient = recipient
      @another = another
    end

    def self.last_order
      return @recipient, @another
    end

    def self.from_row(row)
      ee = CensusRecord.new
      %w[itself to_digits itself itself to_digits 
         to_date_safe to_date_safe to_date_safe itself
         itself itself itself
         itself itself downcase].each_with_index do |conversion, index|
        begin
          ee.send("#{ee.members[index]}=", row[index].send(conversion))
        rescue
          raise row.inspect
        end
      end
      ee = nil if ee.fein.nil? || ee.ssn.nil? || ee.dob.nil? || ee.doh.nil?
      ee
    end

    def self.attribute_sort_order
      %w[fein ssn dob doh]
    end

    def sort_attributes
      self.class.attribute_sort_order.collect do |attribute|
        sort_attribute = self.send(attribute)
      end
    end

    def <=>(another)
      self.class.set_last_order(self, another)
      sort_attributes <=> another.sort_attributes
    end
  end
end
