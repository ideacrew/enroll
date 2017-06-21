class EmployerAttestationDocument < Document
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include AASM

  field :aasm_state, type: String, default: "submitted"
  embedded_in :employer_attestation

  field :reason_for_rejection, type: String

  aasm do
    state :submitted, initial: true
    state :accepted
    state :rejected

    event :accept do
      transitions from: :submitted, to: :accepted
    end

    event :reject do
      transitions from: :submitted, to: :rejected
    end
  end

  def upload_document(file_path,file_name,subject,size)
    #doc_uri = Aws::S3Storage.save(file_path,'id-verification')
    #file = File.open(file_path, "r:ISO-8859-1")

    tmp_file = "#{Rails.root}/tmp/#{file_name}"
    id = 0
    while File.exists?(tmp_file) do
      tmp_file = "#{Rails.root}/tmp/#{id}_#{file_name}"
      id += 1
    end
    # Save to temp file
    File.open(tmp_file, 'wb') do |f|
      f.write File.open(file_path).read
    end
    if(file_path)
      self.document = Document.new unless self.document?
      document = self.document
      document.identifier = tmp_file
      document.format = 'application/pdf'
      document.subject = subject
      document.title =file_name
      document.creator = self.employer_attestation.employer_profile.legal_name
      document.publisher = "test"
      document.type = "EmployeeProfile"
      document.format = 'pdf',
      document.source = 'test'
      document.language = 'English'
      #document.size =  size
      document.date = Date.today
      document.save!

      #self.documents << document
      logger.debug "associated file #{file_path} with the Employer Profile"
      return document
    end
  end

end