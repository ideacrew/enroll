class TranscriptGenerator

  attr_accessor :cv_path, :identifier

  TRANSCRIPT_PATH = "#{Rails.root}/transcript_files/"

  def initialize
    @identifier = 'hbx_id'
    my_logger
  end

  def my_logger
    @my_logger ||= Logger.new("#{Rails.root}/log/my.log")
  end

  def execute
    create_directory(TRANSCRIPT_PATH)

    Dir.glob("#{Rails.root}/sample_xmls/*.xml").each do |file_path|
      begin
        # xml_doc = Nokogiri::XML(File.read(file_path))

        individual_parser = Parsers::Xml::Cv::Importers::IndividualParser.new(File.read(file_path))
        build_transcript(individual_parser.get_person_object)
      rescue Exception  => e
        my_logger.info("failed to process #{file_path}")
      end
    end
  end

  def build_transcript(external_obj)
    person_transcript = Transcripts::PersonTranscript.new
    person_transcript.find_or_build(external_obj)

    File.open("#{TRANSCRIPT_PATH}/#{external_obj.send(@identifier)}_#{Time.now.to_i}.bin", 'wb') do |file|
      file.write Marshal.dump(person_transcript.transcript)
    end
  end

  def display_transcripts
    count  = 0

    CSV.open('person_change_sets.csv', "w") do |csv|
      csv << ['HBX ID', 'SSN', 'Last Name', 'First Name', 'Action', 'Section:Attribute', 'Value']

      Dir.glob("#{Rails.root}/transcript_files/*.bin").each do |file_path|
        begin
          count += 1
          rows = Transcripts::ComparisonResult.new(Marshal.load(File.open(file_path))).csv_row
          next unless rows.present?

          first_row = rows[0]
          rows.reject!{|row| row[4] == 'update' && row[6].blank?}

          if rows.empty?
            csv << (first_row[0..3] + ['match', 'match:ssn'])
          else
            rows.each{|row| csv << row}
          end

          if count % 100 == 0
            puts "processed #{count}"
          end
        rescue Exception => e
          puts "Failed.....#{file_path}"
        end
      end
    end
  end

  private

  def create_directory(path)
    if Dir.exists?(path)
      FileUtils.rm_rf(path)
    end
    Dir.mkdir path
  end
end
