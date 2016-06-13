require 'open-uri'

module AcapiVocabularySpecHelpers
  ACAPI_SCHEMA_FILE_LIST = %w(
assistance.xsd
common.xsd
config.xsd
dms.xsd
document_storage.xsd
edi.xsd
edi_process.xsd
individual.xsd
links.xsd
organization.xsd
plan.xsd
policy.xsd
premium.xsd
verification_services.xsd
vocabulary.xsd
verification_services.xsd
  )

  def download_vocabularies
    schema_directory = File.join(Rails.root, "spec", "vocabularies")
    unless File.exist?(schema_directory)
      Dir.mkdir(schema_directory)
      ACAPI_SCHEMA_FILE_LIST.each do |item|
        download_schema_file(item, schema_directory)
      end
    end
  end

  def download_schema_file(file, s_dir)
    f_name = File.join(s_dir, file)
    unless File.exist?(f_name)
      uri = "https://raw.githubusercontent.com/dchbx/cv/master/#{file}"
      download = open(uri)
      IO.copy_stream(download, f_name)
    end
  end

  def validate_with_schema(document)
    schema_location = File.join(Rails.root, "spec", "vocabularies", "vocabulary.xsd")
    schema = Nokogiri::XML::Schema(File.open(schema_location))
    schema.validate(document).map(&:message)
  end
end
