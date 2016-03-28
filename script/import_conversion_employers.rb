result_file = File.open("Kaiser Import Results.csv", 'wb')

in_file = File.join(Rails.root, "Kaiser 0701 Employer Groups.xlsx")

importer = Importers::ConversionEmployerSet.new(in_file, result_file)

importer.import!
