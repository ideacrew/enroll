class CensusEmployeeImport
  extend  ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :file, :employer_profile

  TEMPLATE_DATE = Date.new(2015, 9, 6)
  TEMPLATE_VERSION = "1.0"
  TEMPLATE_DATE_CELL = "1,'J'"
  TEMPLATE_VERSION_CELL = "1,'K'"

  MEMBER_RELATIONSHIP_KINDS = %w(ee spouse domestic_partner child)

  CENSUS_MEMBER_RECORD = %w(
      employer_assigned_family_id 
      employee_relationship 
      last_name 
      first_name 
      middle_name 
      name_suffix 
      email 
      ssn 
      dob 
      gender
      hire_date 
      termination_date
      is_business_owner
      benefit_group
    )

  CENSUS_MEMBER_RECORD_TITLES = [
      "Family ID #(to match family members to the EE)",
      "Relationship(EE, Spouse, Domestic Partner, or Child)",
      "Last Name",
      "First Name",
      "Middle Name or Initial(optional)",
      "Suffix(optional)",
      "Email Address",
      "SSN / TIN(Required for EE)",
      "Date of Birth",
      "Gender",
      "Date of Hire",
      "Date of Termination(optional)",
      "Is Business Owner?",
      "Benefit Group(optional)"
    ]

  def initialize(attributes = {})
    attributes.each { |name, value| send("#{name}=", value) }

    raise ArgumentError, "Must provide an import file" unless defined?(@file)
    raise ArgumentError, "Must provide an EmployerProfile" unless defined?(@employer_profile)
  end

  def persisted?
    false
  end

  def imported_census_employees
    @imported_census_employees ||= load_imported_census_employees
  end

  def load_imported_census_employees
    # file = 'spec/test_data/spreadsheet_templates/DCHL Employee Census.xlsx'
    roster = Roo::Spreadsheet.open(@file.original_filename)

    @sheet = roster.sheet(0)
    @last_ee_member = {}

    # To match spreadsheet convention, Roo gem uses 1-based (rather than 0-based) references 
    # First three rows are header content
    sheet_header_row  = @sheet.row(1)
    column_header_row = @sheet.row(2)
    # label_header_row  = @sheet.row(3)

    unless header_valid?(sheet_header_row) && column_header_valid?(column_header_row)
      raise "Unrecognized Employee Census spreadsheet format. Contact DC Health Link for current template." 
    end

    (4..@sheet.last_row).each do |i|
      row = Hash[[column_header_row, roster.row(i)].transpose] 
      record = parse_row(row)

      if record[:termination_date].present?
        census_employee = terminate_employee(record) if record[:employee_relationship].downcase == "employee"
      else
        census_employee = add_or_update_census_member(record)
      end

      census_employee ||= nil
    end
  end

  def terminate_employee(record)
    employee = unscoped.by_employer_profile(@employer_profile._id).by_ssn(record[:ssn]).active
    if employee.present?
      employee.terminate_employment(record[:termination_date])
      employee.save
      employee = unscoped.by_employer_profile(@employer_profile._id).by_ssn(record[:ssn]).terminated.order(:employment_terminated_on.desc).first
    end
  end

  # change attributes, add or remove dependents
  def add_or_update_census_member(record)
    # Process Employee
    if record[:employee_relationship].downcase == "employee"
      member = unscoped.by_employer_profile(@employer_profile._id).by_ssn(ssn).active || new
      member.attributes = record.to_hash.slice(*CensusEmployee.accessible_attributes)
      @last_ee_member = member
    else
      # Process dependent
      if record[:employer_assigned_family_id] == @last_ee_member[:employer_assigned_family_id]
        member = census_dependent
      end
    end

    member ||= nil
  end

  def parse_row(row)
    employer_assigned_family_id = parse_text(row[:employer_assigned_family_id])
    employee_relationship = parse_relationship(row[:employee_relationship])
    last_name             = parse_text(row[:last_name])
    first_name            = parse_text(row[:first_name])
    middle_initial        = parse_text(row[:middle_initial])
    name_sfx              = parse_text(row[:name_sfx])
    email                 = parse_text(row[:email])
    ssn                   = parse_ssn(row[:ssn])
    dob                   = parse_date(row[:dob])
    gender                = parse_text(row[:gender])
    hire_date             = parse_date(row[:hire_date])
    termination_date      = parse_date(row[:termination_date])
    is_business_owner     = parse_boolean(row[:is_business_owner])
    benefit_group         = parse_text(row[:benefit_group])

    { 
      employer_assigned_family_id: employer_assigned_family_id,
      employee_relationship: employee_relationship,
      last_name: last_name,
      first_name: first_name,
      middle_initial: middle_initial,
      name_sfx: name_sfx,
      email: email,
      ssn: ssn,
      dob: dob,
      gender: gender,
      hire_date: hire_date,
      termination_date: termination_date,
      is_business_owner: is_business_owner,
      benefit_group: benefit_group,
    }
  end

  def header_valid?(sheet_header_row)
    parse_date(sheet_header_row(TEMPLATE_DATE_CELL)) == TEMPLATE_DATE && 
    sheet_header_row(TEMPLATE_VERSION_CELL) == TEMPLATE_VERSION
  end

  def column_header_valid?(column_header_row)
    clean_header = column_header_row.reduce([]) { |memo, header_text| memo << sanitize_value(header_text) }
    clean_header == CENSUS_MEMBER_RECORD
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
        "child"
      when "disabled child"
        "disabled_child"
      else
        nil
    end
     
    field_map
  end

  def parse_text(cell)
    cell.blank? ? nil : sanitize_value(cell)
  end


  def parse_date(cell)
    return nil if cell.blank?
    return DateTime.strptime(cell.sanitize_value, "%d/%m/%Y") rescue raise ImportErrorValue, cell if cell.class == String
    return cell.to_s.sanitize_value.to_time.strftime("%m-%d-%Y") rescue raise ImportErrorDate, cell if cell.class == String
    # return cell.sanitize_value.to_date.to_s(:db) rescue raise ImportErrorValue, cell if cell.class == String

    cell.blank? ? nil : cell
  end

  def parse_ssn(cell)
    cell.blank? ? nil : cell.to_s.gsub(/\D/, '')
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
    if imported_census_employees.map(&:valid?).all?
      imported_census_employees.each(&:save!)
      true
    else
      imported_census_employees.each_with_index do |census_employee, index|
        census_employee.errors.full_messages.each do |message|
          errors.add :base, "Row #{index + 2}: #{message}"
        end
      end
      false
    end
  end

  def open_spreadsheet
    case File.extname(file.original_filename)
      when ".csv" then Csv.new(file.path, nil, :ignore)
      when ".xls" then Excel.new(file.path, nil, :ignore)
      when ".xlsx" then Excelx.new(file.path, nil, :ignore)
      else raise "Unknown file type: #{file.original_filename}"
    end
  end

private
  def sanitize_value(value)
    value.gsub(/[[:cntrl:]]|^[\p{Space}]+|[\p{Space}]+$/, '')
  end

end

class ImportErrorValue < Exception; end
class ImportErrorDate < Exception; end

