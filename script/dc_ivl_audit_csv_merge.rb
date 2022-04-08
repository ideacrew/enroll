require "csv"

file_list = Dir.glob("audit_ivl_determinations_*.csv")

CSV.open("merged_audit_ivl_determinations.csv", "wb") do |out_csv|
  out_csv << [
    "Family ID",
    "Hbx ID",
    "Last Name",
    "First Name",
    "Full Name",
    "Date of Birth",
    "Gender",
    "Application Date",
    "Primary Applicant",
    "Relationship",
    "Citizenship Status",
    "American Indian",
    "Incarceration",
    "Home Street 1",
    "Home Street 2",
    "Home City",
    "Home State",
    "Home Zip",
    "Mailing Street 1",
    "Mailing Street 2",
    "Mailing City",
    "Mailing State",
    "Mailing Zip",
    "No DC Address",
    "Residency Exemption Reason",
    "Is applying for coverage",
    "Resident Role",
    "Eligible",
    "Denial Reasons"
  ]
  file_list.each do |f|
    CSV.foreach(f, headers: true) do |row|
      out_csv << row.fields.to_a
    end
  end
end
