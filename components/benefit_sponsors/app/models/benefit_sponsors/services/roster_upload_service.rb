module BenefitSponsors
  module Services
    class RosterUploadService

      attr_accessor :file, :profile, :sheet

      TEMPLATE_DATE_CELL = 7
      TEMPLATE_VERSION_CELL = 13

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

      EmployeeTerminationMap = Struct.new(:employee, :termination_date)
      EmployeeAddMap = Struct.new(:employee)

      def initialize(file, profile)
        @file = file
        @profile = profile
      end

      def load_form_metadata(form)
        roster = Roo::Spreadsheet.open(file.tempfile.path)
        @sheet = roster.sheet(0)
        row = sheet.row(1)
        form.file = file
        form.profile = profile
        form.sheet = sheet
        form.template_date = row[TEMPLATE_DATE_CELL]
        form.template_version = row[TEMPLATE_VERSION_CELL]
        form.census_titles = CENSUS_MEMBER_RECORD
        form.census_records = load_census_records_form
        form
      end

      def load_census_records_form
        census_records = []
        columns = sheet.row(2)
        (4..sheet.last_row).inject([]) do |result, id|
          row = Hash[[columns, sheet.row(id)].transpose]
          result << Forms::CensusRecordForm.new(
            employer_assigned_family_id: parse_text(row["employer_assigned_family_id"]),
            employee_relationship: parse_relationship(row["employee_relationship"]),
            last_name: parse_text(row["last_name"]),
            first_name: parse_text(row["first_name"]),
            middle_name: parse_text(row["middle_name"]),
            name_sfx: parse_text(row["name_sfx"]),
            email: parse_text(row["email"]),
            ssn: parse_ssn(row["ssn"]),
            dob: parse_date(row["dob"]),
            gender: parse_text(row["gender"]),
            hire_date: parse_date(row["hire_date"]),
            termination_date: parse_date(row["termination_date"]),
            is_business_owner: parse_boolean(row["is_business_owner"]),
            benefit_group: parse_text(row["benefit_group"]),
            plan_year: parse_text(row["plan_year"]),
            kind: parse_text(row["kind"]),
            address_1: parse_text(row["address_1"]),
            address_2: parse_text(row["address_2"]),
            city: parse_text(row["city"]),
            state: parse_text(row["state"]),
            zip: parse_text(row["zip"]),
            newly_designated: parse_boolean(row["newly_designated"])
          )
          result
        end
      end

      def save(form)
        @profile = form.profile
        @terminate_queue = {}
        @persist_queqe = {}
        form.census_records.each do |record|
          if record.termination_date.present?
            _insert_into_terms_queqe(record)
          else
            _insert_into_persist_queqe(record)
          end
        end

        persist_census_records if @persist_queqe.present?
        terminate_census_records if @terminate_queue.present?
      end

      def persist_census_records

      end

      def terminate_census_records
        # TODO
        @terminate_queue.each do |row, employee_termination_map|
           employee_termination_map.employee.terminate_employment(employee_termination_map.termination_date)
        end
      end

      def _insert_into_terms_queqe(record)
        census_employee = find_employee(record)
        if census_employee.present?
          if is_employee_terminable?(census_employee)
            @terminate_queue[index + 4] = EmployeeTerminationMap.new(census_employee, record.termination_date)
            validate_newly_designated(record.newly_designated, census_employee)
          else
            self.errors.add :base, "Row #{index + 4}: Could not terminate employee"
          end
          # @last_ee_member = census_employee
          # @last_ee_member_record = record
        else
          self.errors.add :base, "Row #{index + 4}: Could not find employee"
        end
      end

      def _insert_into_persist_queqe(record)
        # TODO
        if record.employee_relationship == "self"
          _insert_primary(record)
          # TODO - add EE to queqe with census dependets info
          # census_employee = find_employee(record) || CensusEmployee.new
        else
          _insert_dependent(record)
        end
      end

      def _insert_primary(record)
        # TODO
        member = find_employee(record) || CensusEmployee.new
        member = init_census_record(member, record)
        validate_newly_designated(record.newly_designated, member)
        @primary_census_employee = member
        @primary_record = record
      end

      def _insert_dependent(record)
        return nil if (@primary_census_employee.nil? || @primary_record.nil?)
        if record.employer_assigned_family_id == @primary_record.employer_assigned_family_id
          census_dependent = find_dependent(record)

          params = sanitize_params(record)
          if census_dependent
            census_dependent.assign_attributes(params)
          else
            census_dependent = @primary_census_employee.census_dependents.build(params)
          end
          census_dependent
        end
      end

      def validate_newly_designated(val, census_employee)
        if val == '1'
          begin
            census_employee.newly_designate
          rescue Exception => e
            self.errors.add :base, "employee can't transition to newly designate state #{e.to_s}"
          end
        elsif val == '0'
          if census_employee.may_rebase_new_designee?
            census_employee.rebase_new_designee
          end
        end
      end

      def init_census_record(member, record)
        # TODO
        params = sanitize_params(record).merge!({
          hired_on: record.hire_date,
          is_business_owner: is_business_owner?(record),
          email: build_email(record),
          employee_relationship: record.employee_relationship,
          employer_profile: profile,
          address: build_address(record)
        })
        member.assign_attributes(params)
        # TODO - benefit application
        member
      end

      def build_address(record)
        address = Address.new({
          kind: 'home',
          address_1: record.address_1,
          address_2: record.address_2,
          city: record.city,
          state: record.state,
          zip: record.zip
        })
        address.valid? ? address : nil
      end

      def build_email(record)
        # TODO
        Email.new({address: record.email.to_s, kind: "home"}) if record.email
      end

      def is_business_owner?(record)
        if ["1", "true"].include? record.is_business_owner.to_s
          return true
        end
        false
      end

      def  find_employee(record)
        # TODO
        CensusEmployee.find_by_employer_profile(profile).by_ssn(record.ssn).active.first
      end

      def find_dependent(record)
        # TODO
        @primary_census_employee.census_dependents.detect do |dependent|
          (dependent.ssn == record.ssn) && (dependent.dob == record.dob)
        end
      end

      def sanitize_params(record)
        record.attributes.slice(:employer_assigned_family_id, :employee_relationship, :last_name, :first_name, :middle_name, :name_sfx, :ssn, :dob, :gender)
      end

      def sanitize_primary_params(record)
      end

      def is_employee_terminable?(census_employee)
        #this logic may become more sophisticated in future
        census_employee.may_terminate_employee_role?
      end

      def parse_relationship(cell)
        return nil if cell.blank?
        case parse_text(cell).downcase
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
      end

      def parse_text(cell)
        cell.blank? ? nil : sanitize_value(cell)
      end

      def parse_date(cell)
        return nil if cell.blank?
        return DateTime.strptime(cell.sanitize_value, "%d/%m/%Y") rescue raise ImportErrorValue, cell if cell.class == String
        return cell.to_s.sanitize_value.to_time.strftime("%m-%d-%Y") rescue raise ImportErrorDate, cell if cell.class == String

        cell.blank? ? nil : cell
      end

      def parse_ssn(cell)
        cell.blank? ? nil : cell.to_s.gsub(/\D/, '')
      end

      def parse_boolean(cell)
        cell.blank? ? nil : cell.match(/(true|t|yes|y|1)$/i) != nil ? "1" : "0"
      end

      def sanitize_value(value)
        value = value.to_s.split('.')[0] if value.is_a? Float
        value.gsub(/[[:cntrl:]]|^[\p{Space}]+|[\p{Space}]+$/, '')
      end
    end
  end
end

class ImportErrorValue < Exception;
end

class ImportErrorDate < Exception;
end
