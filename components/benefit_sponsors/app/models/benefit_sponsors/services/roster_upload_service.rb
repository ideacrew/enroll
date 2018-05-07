module BenefitSponsors
  module Services
    class RosterUploadService
      include ActiveModel::Validations

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
      EmployeePersistMap = Struct.new(:employee)

      def initialize(args = {})
        @file = args[:file]
        @profile = args[:profile]
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
        form.census_records.each_with_index do |census_form, i|
          @index = i
          if census_form.termination_date.present?
            _insert_into_terms_queqe(census_form)
          else
            _insert_into_persist_queqe(census_form)
          end
        end
        unless persist_census_records(form) && terminate_census_records
          form.redirection_url = "/employers/employer_profiles/employee_csv_upload_errors"
          return false
        end
        form.redirection_url = "/benefit_sponsors/profiles/employers/employer_profiles/#{profile.id}?tab=employees"
        true
      end

      def persist_census_records(form)
        if @persist_queqe.present?
          employees = @persist_queqe.values.map(&:employee)
          if employees.map(&:valid?).all? || self.errors.blank?
            employees.compact.each(&:save!)
          else
            map_errors_for(self, onto: form)
            employees.each_with_index do |record, i|
              map_errors_for(record, i, onto: form)
            end
            return false
          end
        end
        true
      end

      def map_errors_for(obj, key="", onto:)
        obj.errors.each do |att, err|
          row = key.present? ? "Row #{key + 4}:" : ""
          onto.errors.add(:base, row + "#{att} #{err}")
        end
      end

      def terminate_census_records
        # TODO
        if @terminate_queue.present?
          return false if self.errors.present?
          @terminate_queue.each do |row, employee_termination_map|
            employee_termination_map.employee.terminate_employment(employee_termination_map.termination_date)
          end
        end
        true
      end

      def _insert_into_terms_queqe(form)
        census_employee = find_employee(form.ssn)
        if census_employee.present?
          if is_employee_terminable?(census_employee)
            @terminate_queue[@index + 4] = EmployeeTerminationMap.new(census_employee, form.termination_date)
            validate_newly_designated(form.newly_designated, census_employee)
          else
            self.errors.add :base, "Row #{@index + 4}: Could not terminate employee"
          end
        else
          self.errors.add :base, "Row #{@index + 4}: Could not find employee"
        end
      end

      def _insert_into_persist_queqe(form)
        if form.employee_relationship == "self"
          _insert_primary(form)
        else
          _insert_dependent(form)
        end
      end

      def _insert_primary(form)
        binding.pry
        # TODO
        member = find_employee(form.ssn) || CensusMembers::CensusEmployee.new
        member = init_census_record(member, form)
        @persist_queqe[@index + 4] = EmployeePersistMap.new(member)
        validate_newly_designated(form.newly_designated, member)
        @primary_census_employee = member
        @primary_record = form
      end

      def _insert_dependent(form)
        return nil if (@primary_census_employee.nil? || @primary_record.nil?)
        if form.employer_assigned_family_id == @primary_record.employer_assigned_family_id
          census_dependent = find_dependent(form)

          params = sanitize_params(form)
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

      def init_census_record(member, form)
        # TODO
        params = sanitize_params(form).merge!({
          hired_on: form.hire_date,
          is_business_owner: is_business_owner?(form),
          email: build_email(form),
          employee_relationship: form.employee_relationship,
          # employer_profile_id: profile.id,
          address: build_address(form)
        })
        member.assign_attributes(params)
        # TODO - benefit application
        member
      end

      def build_address(form)
        address = Address.new({
          kind: 'home',
          address_1: form.address_1,
          address_2: form.address_2,
          city: form.city,
          state: form.state,
          zip: form.zip
        })
        address.valid? ? address : nil
      end

      def build_email(form)
        # TODO
        Locations::Email.new({address: form.email.to_s, kind: "home"}) if form.email
      end

      def is_business_owner?(form)
        if ["1", "true"].include? form.is_business_owner.to_s
          return true
        end
        false
      end

      def  find_employee(ssn)
        # TODO
        profile.census_employees.active.by_ssn(ssn).first
      end

      def find_dependent(form)
        # TODO
        @primary_census_employee.census_dependents.detect do |dependent|
          (dependent.ssn == form.ssn) && (dependent.dob == form.dob)
        end
      end

      def sanitize_params(form)
        form.attributes.slice(:employer_assigned_family_id, :employee_relationship, :last_name, :first_name, :middle_name, :name_sfx, :ssn, :dob, :gender)
      end

      def sanitize_primary_params(form)
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
