module BenefitSponsors
  module Services
    class RosterUploadService
      include ActiveModel::Validations

      attr_accessor :file, :profile, :sheet

      TEMPLATE_DATE_CELL = 7
      TEMPLATE_VERSION_CELL = 13

      CENSUS_MEMBER_RECORD = %w[
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
      ].freeze

      EmployeeTerminationMap = Struct.new(:employee, :employment_terminated_on)
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
            employee_relationship: parse_relationship(row["employee_relationship"], parse_date(row["dob"])),
            last_name: parse_text(row["last_name"]),
            first_name: parse_text(row["first_name"]),
            middle_name: parse_text(row["middle_name"]),
            name_sfx: parse_text(row["name_sfx"]),
            ssn: parse_ssn(row["ssn"]),
            dob: parse_date(row["dob"]),
            gender: parse_text(row["gender"]),
            hired_on: parse_date(row["hire_date"]),
            employment_terminated_on: parse_date(row["termination_date"]),
            is_business_owner: parse_boolean(row["is_business_owner"]),
            benefit_group: parse_text(row["benefit_group"]),
            plan_year: parse_text(row["plan_year"]),
            newly_designated: parse_boolean(row["newly_designated"]),
            email: Forms::EmailForm.new(email_params(row)),
            address: Organizations::OrganizationForms::AddressForm.new(address_params(row))
          )
          result
        end
      end

      def address_params(row)
        {
          kind: parse_text(row["kind"]),
          address_1: parse_text(row["address_1"]),
          address_2: parse_text(row["address_2"]),
          city: parse_text(row["city"]),
          state: parse_text(row["state"]),
          zip: parse_text(row["zip"])
        }
      end

      def email_params(row)
        {
          kind: "home" || parse_text(row["email_kind"]), # Add this row to template
          address: parse_text(row["email"])
        }
      end

      def save(form)
        @profile = form.profile
        @terminate_queue = {}
        @persist_queqe = {}
        form.census_records.each_with_index do |census_form, i|
          @index = i
          if census_form.employment_terminated_on.present?
            _insert_into_terms_queqe(census_form)
          else
            _insert_into_persist_queqe(census_form)
          end
        end
        unless persist_census_records(form) && terminate_census_records
          form.redirection_url = "/benefit_sponsors/profiles/employers/employer_profiles/_employee_csv_upload_errors"
          return false
        end
        form.redirection_url = "/benefit_sponsors/profiles/employers/employer_profiles/#{profile.id}?tab=employees"
        true
      end

      def persist_census_records(form)
        if @persist_queqe.present?
          employees = @persist_queqe.values.map(&:employee)
          if employees.map(&:valid?).all? && self.errors.blank?
            employees.compact.each(&:save!)
          else
            map_errors_for(self, onto: form)
            @persist_queqe.each do |key, value|
              map_errors_for(value.employee, key, onto: form)
            end
            return false
          end
        end
        true
      end

      def map_errors_for(obj, key = "", onto:)
        obj.errors.each do |att, err|
          row = key.present? ? "base Row #{key}: " : ""
          onto.errors.add(:base, row + "#{att} #{err}")
        end
      end

      def terminate_census_records
        if @terminate_queue.present?
          return false if self.errors.present?
          @terminate_queue.each do |_row, employee_termination_map|
            employee_termination_map.employee.terminate_employment(Date.strptime(employee_termination_map.employment_terminated_on, '%m/%d/%Y'))
          end
        end
        true
      end

      def _insert_into_terms_queqe(form)
        census_employee = find_employee(form.ssn)
        if census_employee.present?
          if is_employee_terminable?(census_employee)
            @terminate_queue[@index + 4] = EmployeeTerminationMap.new(census_employee, form.employment_terminated_on)
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
        member = find_employee(form.ssn) || ::CensusEmployee.new
        member = init_census_record(member, form)
        @persist_queqe[@index + 4] = EmployeePersistMap.new(member)
        validate_newly_designated(form.newly_designated, member)
        @primary_census_employee = member
        @primary_record = form
      end

      def _insert_dependent(form)
        return nil if @primary_census_employee.nil? || @primary_record.nil?
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
            self.errors.add :base, "employee can't transition to newly designate state #{e}"
          end
        elsif val == '0'
          census_employee.rebase_new_designee if census_employee.may_rebase_new_designee?
        end
      end

      def init_census_record(member, form)
        params = sanitize_params(form).merge!({ hired_on: parse_date(form.hired_on),
                                                is_business_owner: is_business_owner?(form),
                                                email: build_email(form),
                                                employee_relationship: form.employee_relationship,
                                                benefit_sponsors_employer_profile_id: profile.id,
                                                benefit_sponsorship_id: profile.active_benefit_sponsorship.id,
                                                address: build_address(form)})
        member.assign_attributes(params)
        member.no_ssn_allowed = true if profile.active_benefit_sponsorship.is_no_ssn_enabled
        assign_benefit_package_assignments(form, member)
        member
      end

      def assign_benefit_package_assignments(form, member)
        return unless form.benefit_group.present? || form.plan_year.present?
        application = profile.benefit_applications.by_year(form.plan_year.to_i).first
        return unless application.blank?
        benefit_package = application.benefit_packages.where(title: form.benefit_group).first
        return unless benefit_package.blank?

        assignment = build_benefit_package_assignment(benefit_package)

        employee.benefit_group_assignments.each do |bga|
          bga.assign_attributes(is_active: false, end_on: [assignment.start_on - 1.day, bga.start_on].max) if bga.is_active?
        end
        member.benefit_group_assignments << assignment
        member
      end

      def build_benefit_package_assignment(benefit_package)
        ::BenefitGroupAssignment.new(
          benefit_package_id: benefit_package.id,
          start_on: benefit_package.start_on,
          is_active: true,
          activated_at: TimeKeeper.datetime_of_record
        )
      end

      def build_address(form)
        address = ::Address.new(sanitize_address_params(form.address))
        address.valid? ? address : nil
      end

      def build_email(form)
        ::Email.new(sanitize_email_params(form.email)) if form.email
      end

      def is_business_owner?(form)
        return true if ["1", "true"].include? form.is_business_owner.to_s
        false
      end

      def find_employee(ssn)
        profile.census_employees.active.by_ssn(ssn).first
      end

      def find_dependent(form)
        @primary_census_employee.census_dependents.detect do |dependent|
          (dependent.ssn == form.ssn) && form.dob.present? && (dependent.dob == Date.strptime(form.dob, '%m/%d/%Y'))
        end
      end

      def sanitize_address_params(form)
        form.attributes.slice(:address_1, :address_2, :state, :city, :zip, :kind)
      end

      def sanitize_email_params(form)
        form.attributes.slice(:address, :kind)
      end

      def sanitize_params(form)
        form.attributes.slice(:employer_assigned_family_id, :employee_relationship, :last_name, :first_name, :middle_name, :name_sfx, :ssn, :gender).merge({dob: (Date.strptime(form.dob, "%m/%d/%Y") if form.dob.present?)})
      end

      def sanitize_primary_params(form); end

      def is_employee_terminable?(census_employee)
        #this logic may become more sophisticated in future
        census_employee.may_terminate_employee_role?
      end

      def parse_relationship(cell, dob)
        return nil if cell.blank?

        case parse_text(cell).downcase
        when "employee"
          "self"
        when "spouse"
          "spouse"
        when "domestic partner"
          "domestic_partner"
        when "child"
          return nil if dob.nil?
          age = Date.today.year - dob.year
          if age <= 26
            "child_under_26"
          else
            "child_26_and_over"
          end
        when "disabled child"
          "disabled_child_26_and_over"
        end
      end

      def parse_text(cell)
        cell.blank? ? nil : sanitize_value(cell)
      end

      def parse_date(cell)
        return nil if cell.blank?

        if cell.instance_of?(String)
          begin
            Date.strptime(sanitize_value(cell), "%m/%d/%Y")
          rescue StandardError
            begin
              Date.strptime(sanitize_value(cell), "%m-%d-%Y")
            rescue StandardError
              "#{cell} Invalid Format"
            end
          end
        else
          cell
        end
      end

      def parse_ssn(cell)
        return nil if cell.blank?
        value = cell.to_i.to_s.gsub(/\D/, '')
        value.length.between?(7,8) ? value.rjust(9, "0") : value
      end

      def parse_boolean(cell)
        if cell.blank?
          nil
        else
          cell.match(/(true|t|yes|y|1)$/i).nil? ? "0" : "1"
        end
      end

      def sanitize_value(value)
        value = value.to_s.split('.')[0] if value.is_a? Float
        value.to_s.gsub(/[[:cntrl:]]|^\p{Space}+|\p{Space}+$/, '')
      end
    end
  end
end

class ImportErrorValue < Exception;
end

class ImportErrorDate < Exception;
end
