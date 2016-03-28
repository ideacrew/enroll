result_file = File.open("Kaiser Employee Import Results.csv", 'wb')

in_file = File.join(Rails.root, "Kaiser 0701 Employees.xlsx")

importer = Importers::ConversionEmployeeSet.new(in_file, result_file, Date.new(2016,4,1))

importer.import!
