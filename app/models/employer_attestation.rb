class EmployerAttestation
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps
  include AASM

  field :aasm_state, type: String, default: "unsubmitted"

  embedded_in :employer_profile
  embeds_many :employer_attestation_documents, as: :documentable
  embeds_many :workflow_state_transitions, as: :transitional

  aasm do
    state :unsubmitted, initial: true
    state :submitted
    state :pending
    state :approved
    state :denied

    event :submit, :after => :record_transition do 
      transitions from: :unsubmitted, to: :submitted
    end

    event :make_pending, :after => :record_transition do
      transitions from: :submitted, to: :pending
    end

    event :approve, :after => :record_transition do
      transitions from: [:submitted, :pending], to: :approved
    end

    event :deny, :after => :record_transition do
      transitions from: [:submitted, :pending], to: :denied
    end
  end

  def has_documents?
    self.employer_attestation_documents
  end
  
  # def upload_document(file_path,file_name,subject,size)
  #   #doc_uri = Aws::S3Storage.save(file_path,'id-verification')
  #   #file = File.open(file_path, "r:ISO-8859-1")

  #   tmp_file = "#{Rails.root}/tmp/#{file_name}"
  #   id = 0
  #   while File.exists?(tmp_file) do
  #     tmp_file = "#{Rails.root}/tmp/#{id}_#{file_name}"
  #     id += 1
  #   end
  #   # Save to temp file
  #   File.open(tmp_file, 'wb') do |f|
  #     f.write File.open(file_path).read
  #   end
  #   if(file_path)
  #     self.document = Document.new unless self.document?
  #     document = self.document
  #     document.identifier = tmp_file
  #     document.format = 'application/pdf'
  #     document.subject = subject
  #     document.title =file_name
  #     document.creator = self.employer_attestation.employer_profile.legal_name
  #     document.publisher = "test"
  #     document.type = "EmployeeProfile"
  #     document.format = 'pdf',
  #     document.source = 'test'
  #     document.language = 'English'
  #     #document.size =  size
  #     document.date = Date.today
  #     document.save!

  #     #self.documents << document
  #     logger.debug "associated file #{file_path} with the Employer Profile"
  #     return document
  #   end
  # end

  private

  def record_transition
    self.workflow_state_transitions << WorkflowStateTransition.new(
      from_state: aasm.from_state,
      to_state: aasm.to_state
    )
  end
end
