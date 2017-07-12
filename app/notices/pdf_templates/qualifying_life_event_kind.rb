module PdfTemplates
  class QualifyingLifeEventKind
    include Virtus.model

    attribute :start_on, Date
    attribute :end_on, Date
    attribute :effective_on, Date
    attribute :qle_on, Date
    attribute :reason, String
    
  end
end
