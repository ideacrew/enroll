module Forms
  class ConsumerRole < SimpleDelegator
    include ActiveModel::Validations

    attr_accessor :kind, :doc_number

    validates_presence_of :doc_number

    def vlp_document_kinds
      ::ConsumerRole::VLP_DOCUMENT_KINDS
    end

    def self.model_name
      Person.model_name
    end

  end
end
