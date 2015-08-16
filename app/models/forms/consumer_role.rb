module Forms
  class ConsumerRole < SimpleDelegator

    def create_document(file_path)
      documents.build
    end

    def vlp_document_kinds
      ConsumerRole::VLP_DOCUMENT_KINDS
    end

    def self.model_name
      Person.model_name
    end

  end
end
