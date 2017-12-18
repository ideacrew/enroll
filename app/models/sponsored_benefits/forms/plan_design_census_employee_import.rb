module SponsoredBenefits
  module Forms
    class PlanDesignCensusEmployeeImport < CensusEmployeeImport


      def employee_klass
        SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee
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
          raise "Unrecognized Employee Census spreadsheet format. Contact #{Settings.site.short_name} for current template."
        end

        census_employees = []
        (4..@sheet.last_row).each_with_index.map do |i, index|
          row = Hash[[@column_header_row, @roster.row(i)].transpose]
          record = parse_row(row)

          if record[:termination_date].present? #termination logic
            census_employee = find_employee(record)
            if census_employee.present?
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

          census_employee ||= nil
          census_employees << census_employee
        end
        census_employees
      end

      def assign_benefit_group(member, benefit_group, plan_year)
        member
      end

    end
  end
end
