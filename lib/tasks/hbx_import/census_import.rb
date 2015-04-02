require "tasks/hbx_import/employer_monkeypatch"

module HbxImport
  class CensusImport
    attr_reader :file_name

    def initialize(file_name)
      @file_name = file_name
    end

    def run
      ees = []
      CSV.foreach(file_name, headers: true) do |row|
        ees << CensusRecord.from_row(row)
      end

      ees = ees.reject(&:nil?).sort.uniq

      puts "Found #{ees.size} unique census records in #{ees.collect(&:fein).uniq.size} employers."

      census_employees_to_save = []
      benefit_groups_to_save = []
      ees.each do |ee|
        er = EmployerProfile.find_by_fein(ee.fein)
        if er.present?
          py = er.plan_years.last
          bg = py.benefit_groups.last
          eefs = EmployerProfile.find_census_families_by_person(ee)
          # TODO: make sure first is the right one
          eef = eefs.first
          eef = er.employee_families.build if eef.nil?
          cee = eef.census_employee
          if cee.nil?
            cee = eef.build_census_employee
            cee.first_name = ee.first_name
            cee.last_name = ee.last_name
            cee.ssn = ee.ssn
            cee.dob = ee.dob
            cee.hired_on = ee.doh
            cee.build_email(kind: "work", address: ee.work_email)
            cee.terminated_on = ee.dot
            eef.benefit_group = bg
            bg.employee_families << cee._id
            census_employees_to_save << cee
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
          employee.employee_family.benefit_group.save
          if employee.employee_family.benefit_group.valid?
            status[:saved_benefit_groups] << employee.employee_family.benefit_group
          else
            status[:failed_benefit_groups] << employee.employee_family.benefit_group
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
    :dba, :fein, :first_name, :last_name, :ssn, :dob, :doh, :work_email,
    :person_email, :dot, :individual_external_id, :employee_external_id,
    :record_start_date, :record_end_date
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
      %w[itself to_digits itself itself to_digits to_date_safe to_date_safe itself
         itself to_date_safe itself itself itself itself].each_with_index do |conversion, index|
        ee.send("#{ee.members[index]}=", row[index].send(conversion))
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
