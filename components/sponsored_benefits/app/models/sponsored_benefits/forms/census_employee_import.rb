require 'roo'

module SponsoredBenefits
  module Forms
    class CensusEmployeeImport
      extend ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Validations

      attr_accessor :file, :employer_profile

      validate :check_relationships

      TEMPLATE_DATE = Date.new(2016, 10, 26)
      TEMPLATE_VERSION = "1.1"
      TEMPLATE_DATE_CELL = 7
      TEMPLATE_VERSION_CELL = 13

      MEMBER_RELATIONSHIP_KINDS = %w(employee spouse domestic_partner child)

      EmployeeTerminationMap = Struct.new(:employee, :termination_date)

      CENSUS_MEMBER_RECORD = %w(
        employer_assigned_family_id
        employee_relationship
        last_name
        first_name
        middle_name
        name_sfx
        email
        ssn
        dob
        gender
        hire_date
        termination_date
        is_business_owner
        benefit_group
        plan_year
        kind
        address_1
        address_2
        city
        state
        zip
        newly_designated
        )

      CENSUS_MEMBER_RECORD_TITLES = [
        "Family ID #(to match family members to the EE & each household gets a unique number)",
        "Relationship(EE, Spouse, Domestic Partner, or Child)",
        "Last Name",
        "First Name",
        "Middle Name or Initial(optional)",
        "Suffix(optional)",
        "Email Address",
        "SSN / TIN(Required for EE & enter without dashes)",
        "Date of Birth(MM/DD/YYYY)",
        "Gender",
        "Date of Hire",
        "Date of Termination(optional)",
        "Is Business Owner?",
        "Benefit Group(optional)",
        "Plan Year(Optional)",
        "Address Kind(Optional)",
        "Address Line 1(Optional)",
        "Address Line 2(Optional)",
        "City(Optional)",
        "State(Optional)",
        "Zip(Optional)"
      ]

      def initialize(attributes = {})
        @terminate_queue = {}
        attributes.each { |name, value| send("#{name}=", value) }

        raise ArgumentError, "Must provide an import file" unless defined?(@file)
      end

      def check_relationships
        return true if (@sheet.nil? || @column_header_row.nil?)

        (4..@sheet.last_row).each_with_index.map do |i, index|
          row = Hash[[@column_header_row, @roster.row(i)].transpose]
          record = parse_row(row)
          if record[:employee_relationship].nil?
            self.errors.add :base, "Row #{index + 4}: Relationship is required"
          end
        end
      end

      def persisted?
        false
      end

      def imported_census_employees
        @imported_census_employees ||= load_imported_census_employees
        @imported_census_employees.each do |census_employee|
          if census_employee.is_a?(employee_klass)
            census_employee.errors.add :base, "Email is required" if census_employee.email.blank?
          end
        end
        @imported_census_employees
      end

      def load_imported_census_employees
        # file = 'spec/test_data/spreadsheet_templates/DCHL Employee Census.xlsx'
        @roster = Roo::Spreadsheet.open(@file.tempfile.path)

        @sheet = @roster.sheet(0)
        @last_ee_member = {}
        # To match spreadsheet convention, Roo gem uses 1-based (rather than 0-based) references
        # First three rows are header content
        sheet_header_row = @sheet.row(1)
        @column_header_row = @sheet.row(2)
        # label_header_row  = @sheet.row(3)

        unless header_valid?(sheet_header_row) && column_header_valid?(@column_header_row)
          raise "Unrecognized Employee Census spreadsheet format. Contact #{EnrollRegistry[:enroll_app].setting(:short_name).item} for current template."
        end

        census_employees = []
        (4..@sheet.last_row).each_with_index.map do |i, index|
          row = Hash[[@column_header_row, @roster.row(i)].transpose]
          record = parse_row(row)

          if record[:termination_date].present? #termination logic
            census_employee = find_employee(record)
            if census_employee.present?
              if is_employee_terminable?(census_employee)
                @terminate_queue[index + 4] = EmployeeTerminationMap.new(census_employee, record[:termination_date])
              else
                self.errors.add :base, "Row #{index + 4}: Could not terminate employee"
              end
              @last_ee_member = census_employee
              @last_ee_member_record = record
            end
          else #add or edit census_member logic
            if record[:employee_relationship].nil?
              self.errors.add :base, "Row #{index + 4}: Relationship is required"
              break
            else
              census_employee = add_or_update_census_member(record)
            end
          end

          if record[:newly_designated] == '1'
            begin
              census_employee.newly_designate
            rescue Exception => e
              self.errors.add :base, "employee can't transition to newly designate state #{e.to_s}"
            end
          elsif record[:newly_designated] == '0'
            if census_employee.may_rebase_new_designee?
              census_employee.rebase_new_designee
            end
          end

          census_employee ||= nil
          census_employees << census_employee
        end
        census_employees
      end

      def employee_klass
        SponsoredBenefits::CensusMembers::CensusEmployee
      end

      # change attributes, add or remove dependents
      def add_or_update_census_member(record)
        # Process Employee
        if record[:employee_relationship].downcase == "self"
          member = find_employee(record) || employee_klass.new
          member = assign_census_employee_attributes(member, record)
          @last_ee_member = member
          @last_ee_member_record = record
        else
          # Process dependent
          return nil if (@last_ee_member_record.nil? || @last_ee_member.nil?)
          if record[:employer_assigned_family_id] == @last_ee_member_record[:employer_assigned_family_id]
            census_dependent = @last_ee_member.census_dependents.detect do |dependent|
              (dependent.ssn == record[:ssn]) && (dependent.dob == record[:dob])
            end

            record_slice = record.slice(:employer_assigned_family_id, :employee_relationship, :last_name, :first_name, :name_sfx, :ssn, :dob, :gender)
            if census_dependent
              census_dependent.update_attributes(record_slice)
            else
              census_dependent = @last_ee_member.census_dependents.build(record_slice)
            end
            member = census_dependent
          end
        end

        member ||= nil
      end

      def assign_census_employee_attributes(member, record)
        member.employer_assigned_family_id = record[:employer_assigned_family_id] if record[:employer_assigned_family_id]
        member.ssn = record[:ssn].to_s if record[:ssn]
        member.first_name = record[:first_name].to_s if record[:first_name]
        member.last_name = record[:last_name].to_s if record[:last_name]
        member.middle_name = record[:middle_name].to_s if record[:middle_name]
        member.name_sfx = record[:name_sfx].to_s if record[:name_sfx]
        member.dob = record[:dob] if record[:dob]
        member.hired_on = record[:hire_date] if record[:hire_date]
        member.benefit_sponsorship_id = benefit_sponsorship.id
        # is_business_owner blank or false based on it checkbox value will be set
        if ["0",""].include? record[:is_business_owner].to_s
          member.is_business_owner = false
        else
          member.is_business_owner = true
        end
        member.gender = record[:gender].to_s if record[:gender]
        member.email = Email.new({address: record[:email].to_s, kind: "home"}) if record[:email]
        member.employee_relationship = record[:employee_relationship].to_s if record[:employee_relationship]
        assign_benefit_group(member, record[:benefit_group], record[:plan_year])
        address = SponsoredBenefits::Locations::Address.new({kind: 'home', address_1: record[:address_1], address_2: record[:address_2], city: record[:city],
                               state: record[:state], zip: record[:zip]})
        member.address = address if address.valid?
        member
      end

      def assign_benefit_group(member, benefit_group, plan_year)
        plan_year_found = @employer_profile.plan_years.detect do |py|
          py.start_on.year.to_s == plan_year
        end
        return if plan_year_found.nil?
        return if benefit_group.nil?
        benefit_group_found = plan_year_found.benefit_groups.detect do |bg|
          bg.title.casecmp(benefit_group) == 0
        end
        return if benefit_group_found.nil?
        member.benefit_group_assignments << BenefitGroupAssignment.new({benefit_group_id: benefit_group_found.id, start_on: plan_year_found.start_on})
        member.benefit_group_assignments.last.make_active
      end

      def parse_row(row)
        employer_assigned_family_id = parse_text(row["employer_assigned_family_id"])
        employee_relationship = parse_relationship(row["employee_relationship"])
        last_name = parse_text(row["last_name"])
        first_name = parse_text(row["first_name"])
        middle_name = parse_text(row["middle_name"])
        name_sfx = parse_text(row["name_sfx"])
        email = parse_text(row["email"])
        ssn = parse_ssn(row["ssn"])
        dob = parse_date(row["dob"], "dob")
        gender = parse_text(row["gender"])
        hire_date = parse_date(row["hire_date"], "hire_date")
        termination_date = parse_date(row["termination_date"], "termination_date")
        is_business_owner = parse_boolean(row["is_business_owner"])
        benefit_group = parse_text(row["benefit_group"])
        plan_year = parse_text(row["plan_year"])
        kind = parse_text(row["kind"])
        address_1 = parse_text(row["address_1"])
        address_2 = parse_text(row["address_2"])
        city = parse_text(row["city"])
        state = parse_text(row["state"])
        zip = parse_text(row["zip"])
        newly_designated = parse_boolean(row["newly_designated"])
        {
            employer_assigned_family_id: employer_assigned_family_id,
            employee_relationship: employee_relationship,
            last_name: last_name,
            first_name: first_name,
            middle_name: middle_name,
            name_sfx: name_sfx,
            email: email,
            ssn: ssn,
            dob: dob,
            gender: gender,
            hire_date: hire_date,
            termination_date: termination_date,
            is_business_owner: is_business_owner,
            benefit_group: benefit_group,
            plan_year: plan_year,
            kind: kind,
            address_1: address_1,
            address_2: address_2,
            city: city,
            state: state,
            zip: zip,
            newly_designated: newly_designated
        }
      end

      def header_valid?(sheet_header_row)
        if sheet_header_row[TEMPLATE_DATE_CELL].is_a? Date
          template_date = sheet_header_row[TEMPLATE_DATE_CELL]
        else
          template_date = Date.strptime(sheet_header_row[TEMPLATE_DATE_CELL], "%m/%d/%Y")
        end
        template_date == TEMPLATE_DATE &&
        sheet_header_row[TEMPLATE_VERSION_CELL] == TEMPLATE_VERSION
      end

      def column_header_valid?(column_header_row)
        clean_header = column_header_row.reduce([]) { |memo, header_text| memo << sanitize_value(header_text) }
        clean_header == CENSUS_MEMBER_RECORD || clean_header == CENSUS_MEMBER_RECORD[0..-2]
      end

      def parse_relationship(cell)
        # defined? @last_employer_assigned_family_id ?
        return nil if cell.blank?
        field_map = case parse_text(cell).downcase
                      when "employee"
                        "self"
                      when "spouse"
                        "spouse"
                      when "domestic partner"
                        "domestic_partner"
                      when "child"
                        "child_under_26"
                      when "disabled child"
                        "disabled_child_26_and_over"
                      else
                        nil
                    end

        field_map
      end

      def parse_text(cell)
        cell.blank? ? nil : sanitize_value(cell)
      end

      def parse_date(cell, field_name="date")
        return nil if cell.blank?
        return DateTime.strptime(cell, "%m/%d/%Y") rescue raise ImportErrorValue, "#{field_name.camelcase} Error: Invalid date #{cell}" if cell.class == String
        return cell.to_s.sanitize_value.to_time.strftime("%m-%d-%Y") rescue raise ImportErrorDate, "#{field_name.camelcase} Error: Invalid date #{cell}" if cell.class == String
        # return cell.sanitize_value.to_date.to_s(:db) rescue raise ImportErrorValue, cell if cell.class == String

        cell.blank? ? nil : cell
      end

      def parse_ssn(cell)
        cell.blank? ? nil : prepend_zeros(cell.to_i.to_s.gsub(/\D/, ''), 9)
      end

      def parse_boolean(cell)
        cell.blank? ? nil : cell.match(/(true|t|yes|y|1)$/i) != nil ? "1" : "0"
      end

      def self.parse_boolean(cell)
        cell.blank? ? nil : cell.match(/(true|t|yes|y|1)$/i) != nil ? "1" : "0"
      end

      def self.parse_number(cell)
        cell.blank? ? nil : (Float(cell) rescue raise ImportErrorValue, cell)
      end

      def self.parse_integer(cell)
        cell.blank? ? nil : (Integer(cell) rescue raise ImportErrorValue, cell)
      end

      def save

        if imported_census_employees.compact.map(&:valid?).all? # && (imported_census_employees.exclude? nil)
          if self.errors.present? || !self.valid?
            return false
          end

          imported_census_employees.compact.each(&:save!)
          terminate_employees if @terminate_queue.present?
          true
        else
          imported_census_employees.each_with_index do |census_employee, index|
            if census_employee.nil?
              errors.add :base, "Row #{index + 4}: Employee/Dependent not found or not active"
            else
              census_employee.errors.full_messages.each do |message|
                errors.add :base, "Row #{index + 4}: #{message}"
              end
            end
          end
          false
        end
      end

      def open_spreadsheet
        case File.extname(file.original_filename)
          when ".csv" then
            Csv.new(file.path, nil, :ignore)
          when ".xls" then
            Excel.new(file.path, nil, :ignore)
          when ".xlsx" then
            Excelx.new(file.path, nil, :ignore)
          else
            raise "Unknown file type: #{file.original_filename}"
        end
      end

      def length
        @imported_census_employees.length
      end

      def find_employee(record)
        employee_klass.find_by_employer_profile(@employer_profile).by_ssn(record[:ssn]).active.first
      end

      def terminate_employees
        @terminate_queue.each do |row, employee_termination_map|
           employee_termination_map.employee.terminate_employment(employee_termination_map.termination_date)
        end
      end

      def is_employee_terminable?(employee)
        #this logic may become more sophisticated in future
        employee.may_terminate_employee_role?
      end

      def encrypt_ssn(val)
        if val.blank?
          return nil
        end
        ssn_val = val.to_s.gsub(/\D/, '')
        SymmetricEncryption.encrypt(ssn_val)
      end

      alias_method :count, :length

      private
      def sanitize_value(value)
        value = value.to_s.split('.')[0] if value.is_a? Float
        value.gsub(/[[:cntrl:]]|^[\p{Space}]+|[\p{Space}]+$/, '')
      end

      def prepend_zeros(number, n)
        (n - number.to_s.size).times { number.prepend('0') }
        number
      end
    end

    class ImportErrorValue < Exception;
    end

    class ImportErrorDate < Exception;
    end

  end
end
