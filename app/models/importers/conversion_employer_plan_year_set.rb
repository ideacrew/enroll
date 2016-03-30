module Importers
  class ConversionEmployerPlanYearSet
    HEADERS = [
"Action",
"FEIN",
"Doing Business As",
"Legal Name",
"Physical Address 1",
"Physical Address 2",
"City",
"State",
"Zip",
"Mailing Address 1",
"Mailing Address 2",
"City",
"State",
"Zip",
"Contact First Name",
"Contact Last Name",
"Contact Email",
"Contact Phone",
"Enrolled Employee Count",
"New Hire Coverage Policy",
"Contact Address 1",
"Contact Address 2",
"City",
"State",
"Zip",
"Broker Name",
"Broker NPN",
"TPA Name",
"TPA FEIN",
"Coverage Start Date",
"Carrier Selected",
"Plan Selection Category",
"Plan Name",
"Plan HIOS Id",
"Most Enrollees - Plan Name",
"Most Enrollees - Plan HIOS Id",
"Reference Plan - Name",
"Reference Plan - HIOS Id",
"Employer Contribution -  Employee",
"Employer Contribution - Spouse",
"Employer Contribution - Domestic Partner",
"Employer Contribution - Child under 26",
"Employer Contribution - Child over 26",
"Employer Contribution - Disabled child over 26",
"Import Status",
"Import Details"
    ]

    ROW_MAPPING = [
      :action,
      :fein,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :enrolled_employee_count,
      :new_coverage_policy,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :ignore,
      :carrier,
      :plan_selection
    ]

    def initialize(file_name, o_stream, default_py_start)
      @spreadsheet = Roo::Spreadsheet.open(file_name)
      @out_stream = o_stream
      @out_csv = CSV.new(o_stream)
      @default_plan_year_start = default_py_start
    end

    def row_iterator
      @spreadsheet.kind_of?(Roo::Excelx) ? :process_excel_rows : :process_csv_rows
    end

    def import!
      @out_csv << HEADERS
      self.send(row_iterator)
    end

    def process_csv_rows
      (2..@spreadsheet.last_row).each do |idx|
        convert_row(@spreadsheet.row(idx))
      end
    end

    def process_excel_rows
      @sheet = @spreadsheet.sheet(0)
      (2..@sheet.last_row).each do |idx|
        convert_row(@sheet.row(idx))
      end
    end

    def convert_row(row)
      record_attrs = {}
      out_row = []
      ROW_MAPPING.each_with_index do |k, idx|
        value = row[idx]
        unless (k == :ignore) || value.blank?
          record_attrs[k] = value.to_s.strip.gsub(/\.0\Z/,"")
        end
        record_attrs[:default_plan_year_start] = @default_plan_year_start
      end
      record = ::Importers::ConversionEmployerPlanYear.new(record_attrs)
      import_details = []
      if record.save
        if record.warnings.any?
          import_details = ["imported with warnings", JSON.dump(record.warnings.to_hash)]
        else
          import_details = ["imported", ""]
        end
      else
        import_details = ["import failed", JSON.dump(record.errors.to_hash)] 
      end
      @out_csv << (row.map(&:to_s) + import_details)
    end
  end
end
