class TranscriptGenerator

  attr_accessor :cv_path, :transcripts_path

  def execute
    create_directory(@transcripts_path)

    Dir.glob("#{@cv_path}/*.xml").each do |file_path|
      begin
        xml_doc = Nokogiri::XML(File.open(file_path))
        external_obj = parse_xml(xml_doc)
        build_transcript(external_obj)
      rescue Exception  => e
        puts "failed to process #{file_path}" 
      end
    end
 
    build_transcript(external_obj)
  end

  def parse_xml(xml_doc)
    # Call xml builder
  end

  def build_transcript(external_obj)
    person_transcript = PersonTranscript.new
    person_transcript.find_or_build(external_obj)

    File.open("#{@transcripts_path}/#{Time.now.to_i}_#{external_obj.hbx_id}.json", 'w') do |file|
      file.write person_transcript.transcript.to_json
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
